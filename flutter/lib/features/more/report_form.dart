import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../session/pocket_scope.dart';
import '../../ui/busy_label.dart';
import '../../ui/field_error.dart';
import '../../ui/paths.dart';
import '../../ui/photo_picker.dart';

const _failed = 'The care service did not answer.';
const _need = 'Add a title and the report text or a file.';
const _docLabel = 'Report document';
const _thumb = 96.0;
const _thumbRadius = 12.0;
const _thumbLabel = 'Attached file preview';

/// New report. Save needs a title and either text or a file, then opens the leaf.
class ReportForm extends StatefulWidget {
  const ReportForm({super.key});

  @override
  State<ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<ReportForm> {
  final _title = TextEditingController();
  final _author = TextEditingController();
  final _note = TextEditingController();
  final _original = TextEditingController();
  String? _fileId;
  Uint8List? _fileBytes;
  Phase _filePhase = Phase.idle;
  Phase _phase = Phase.idle;
  String? _error;

  PocketScope get _scope => PocketScope.of(context);

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _note.dispose();
    _original.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final idle = _phase == Phase.idle && _filePhase == Phase.idle;

    return Scaffold(
      appBar: AppBar(title: const Text('Add a report')),
      // Fields scroll; Save + error stay above the IME.
      body: Column(
        children: [
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'The original is kept. A plain-English summary is added beside it.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Title'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _author,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Author'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _note,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Short note'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _original,
                  minLines: 6,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Report text',
                    hintText: 'Paste the report',
                    alignLabelWithHint: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: idle ? _toggleFile : null,
                    // Photo library only until a document picker ships.
                    child: BusyLabel(
                      _fileId == null ? 'Add a photo' : 'Remove attachment',
                      phase: _filePhase,
                    ),
                  ),
                ),
                if (_fileBytes != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(_thumbRadius),
                    child: Image.memory(
                      _fileBytes!,
                      height: _thumb,
                      fit: BoxFit.cover,
                      semanticLabel: _thumbLabel,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: idle ? _save : null,
                    child: BusyLabel('Save report', phase: _phase),
                  ),
                  if (_error case final error?) ...[
                    const SizedBox(height: 12),
                    FieldError(error),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFile() async {
    if (_fileId != null) {
      setState(() {
        _fileId = null;
        _fileBytes = null;
      });
      return;
    }

    setState(() {
      _filePhase = Phase.busy;
      _error = null;
    });

    Uint8List? bytes;
    String? id;
    String? error;

    try {
      bytes = await pickPhoto();
      id = bytes == null
          ? null
          : await _scope.storeDocument(_docLabel, bytes);
    } on Object {
      error = _failed;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _filePhase = Phase.idle;
      _fileId = id;
      _fileBytes = id == null ? null : bytes;
      _error = error;
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final original = _original.text.trim();

    if (title.isEmpty || (original.isEmpty && _fileId == null)) {
      setState(() => _error = _need);
      return;
    }

    setState(() {
      _phase = Phase.busy;
      _error = null;
    });

    String? id;

    try {
      id = await _scope.addReport(
        title: title,
        author: _author.text,
        note: _note.text,
        original: original,
        fileId: _fileId,
      );
    } on Object {
      id = null;
    }

    if (!mounted) {
      return;
    }

    if (id == null) {
      setState(() {
        _phase = Phase.idle;
        _error = _failed;
      });
      return;
    }

    context.pushReplacement(Paths.reportOf(id));
  }
}
