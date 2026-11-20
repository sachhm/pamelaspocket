import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/enums.dart';
import '../../domain/records.dart';
import '../../domain/time.dart';
import '../../session/pocket_scope.dart';
import '../../ui/busy_label.dart';
import '../../ui/paths.dart';
import '../../ui/entry_label.dart';
import '../../ui/field_error.dart';
import '../../ui/flush_button.dart';
import '../../ui/role_label.dart';
import '../../ui/stored_photo.dart';

const _failed = 'The care service did not answer.';
const _noteLines = 4;

/// Whether the owner is reading the entry or rewriting its body.
enum _Mode { read, edit }

/// One diary entry: kind, who and when, the note, its photo. The owner may
/// edit the body or remove the entry; other roles only read.
class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key, required this.id});

  final String id;

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  final _body = TextEditingController();
  _Mode _mode = _Mode.read;
  Phase _phase = Phase.idle;
  String? _error;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = PocketScope.of(context);
    final theme = Theme.of(context);
    final entry = scope.state?.entries
        .where((e) => e.id == widget.id)
        .firstOrNull;

    if (entry == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Update')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This update is no longer in the diary.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go(Paths.today),
                child: const Text('Back to Today'),
              ),
            ],
          ),
        ),
      );
    }

    final owner = scope.actor?.role == Role.owner;
    final when = formatWhen(entry.when, DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Update')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(entryLabel(entry.kind), style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            '${entry.authorName}, ${roleLabel(entry.authorRole)} · $when',
            style: theme.textTheme.bodyMedium!.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          if (_mode == _Mode.edit)
            TextField(
              controller: _body,
              autofocus: true,
              minLines: _noteLines,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Note'),
            )
          else
            Text(entry.body, style: theme.textTheme.bodyLarge),

          for (final id in entry.fileIds) ...[
            const SizedBox(height: 16),
            StoredPhoto(id: id, label: 'Photo with this update'),
          ],

          if (owner) ...[
            const SizedBox(height: 24),
            if (_mode == _Mode.edit) ..._editActions() else _readActions(entry),
          ],
          if (_error case final error?) ...[
            const SizedBox(height: 12),
            FieldError(error),
          ],
        ],
      ),
    );
  }

  Widget _readActions(DiaryEntry entry) {
    return Wrap(
      spacing: 24,
      children: [
        TextButton(
          style: flushButton,
          onPressed: () => _startEdit(entry),
          child: const Text('Edit'),
        ),
        TextButton(
          style: flushDanger,
          onPressed: _phase == Phase.idle ? _remove : null,
          child: BusyLabel('Remove', phase: _phase),
        ),
      ],
    );
  }

  List<Widget> _editActions() {
    return [
      FilledButton(
        onPressed: _phase == Phase.idle ? _saveEdit : null,
        child: BusyLabel('Save', phase: _phase),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: _phase == Phase.idle ? _cancelEdit : null,
        child: const Text('Cancel'),
      ),
    ];
  }

  void _startEdit(DiaryEntry entry) {
    _body.text = entry.body;
    setState(() {
      _mode = _Mode.edit;
      _error = null;
    });
  }

  void _cancelEdit() {
    setState(() {
      _mode = _Mode.read;
      _error = null;
    });
  }

  Future<void> _saveEdit() async {
    final saved = await _run(
      () => PocketScope.of(context).editEntry(widget.id, _body.text),
    );

    if (saved && mounted) {
      setState(() => _mode = _Mode.read);
    }
  }

  Future<void> _remove() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this update?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: dangerButton,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (sure != true || !mounted) {
      return;
    }

    final removed = await _run(
      () => PocketScope.of(context).removeEntry(widget.id),
    );

    if (removed && mounted) {
      // pop() stays on this page once the diary refresh rebuilds the route.
      context.go(Paths.today);
    }
  }

  // Runs one commit with progress; a failure stays under the buttons and
  // keeps the text. True when it succeeded.
  Future<bool> _run(Future<void> Function() commit) async {
    setState(() {
      _phase = Phase.busy;
      _error = null;
    });

    String? error;

    try {
      await commit();
    } on Object {
      error = _failed;
    }

    if (mounted) {
      setState(() {
        _phase = Phase.idle;
        _error = error;
      });
    }

    return error == null;
  }
}
