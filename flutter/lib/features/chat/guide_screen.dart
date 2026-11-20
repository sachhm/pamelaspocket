import 'package:flutter/material.dart';

import '../../domain/chat.dart';
import '../../domain/enums.dart';
import '../../domain/records.dart';
import '../../domain/time.dart';
import '../../session/pocket_scope.dart';
import '../../ui/ai_chip.dart';
import '../../ui/busy_label.dart';
import '../../ui/field_error.dart';
import '../../ui/flush_button.dart';
import '../../ui/paper_motion.dart';

const _failed = 'The care service did not answer.';
const _banner =
    'Only you can see this. Not medical advice. In an emergency, call 000.';

/// Private guide thread for one household person.
///
///   Only you can see this…
///   [A hard day] [Draft a handover] [Draft a family note]
///   …bubbles…
///   [Add to the diary] on a handover draft
///   ┌ Say what’s on your mind ┐ [Send]
class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  final _draft = TextEditingController();
  final _scroll = ScrollController();
  Phase _phase = Phase.idle;
  String? _error;

  @override
  void dispose() {
    _draft.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = PocketScope.of(context);
    final actor = scope.actor;
    final state = scope.state;
    final theme = Theme.of(context);

    if (actor == null || state == null) {
      return const SizedBox.shrink();
    }

    final notes = state.messages.where((n) => n.thread == Thread.guide).toList()
      ..sort((a, b) => compareWritten(a.when, b.when));
    final empty = _draft.text.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Pocket Guide')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  _banner,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final starter in guideStarters)
                      ActionChip(
                        // Theme labelLarge already hits 48 tall; pad the tap.
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        label: Text(starter),
                        onPressed: _phase == Phase.idle
                            ? () => _send(starter)
                            : null,
                      ),
                  ],
                ),

                FreshSlips(
                  ids: [for (final note in notes) note.id],
                  item: (id) {
                    final note = notes.firstWhere((n) => n.id == id);

                    return _GuideBubble(
                      note: note,
                      today: DateTime.now(),
                      onAdd: isDiaryDraft(note)
                          ? () => _addDiary(note.id)
                          : null,
                    );
                  },
                ),
              ],
            ),
          ),

          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.colorScheme.tertiary),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _draft,
                            minLines: 1,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Say what’s on your mind',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: !empty && _phase == Phase.idle
                              ? () => _send(_draft.text)
                              : null,
                          child: BusyLabel(
                            _error == null ? 'Send' : 'Try again',
                            phase: _phase,
                          ),
                        ),
                      ],
                    ),
                    if (_error case final error?) ...[
                      const SizedBox(height: 12),
                      FieldError(error),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send(String text) async {
    final scope = PocketScope.of(context);

    FocusScope.of(context).unfocus();
    setState(() {
      _phase = Phase.busy;
      _error = null;
    });

    try {
      await scope.sendGuide(text);
      _draft.clear();
    } on Object {
      if (mounted) {
        setState(() {
          _phase = Phase.idle;
          _error = _failed;
        });
      }

      return;
    }

    if (mounted) {
      setState(() => _phase = Phase.idle);
      await _toEnd();
    }
  }

  Future<void> _toEnd() async {
    // Wait for the new bubbles to lay out before reading maxScrollExtent.
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;

    if (!mounted || !_scroll.hasClients) {
      return;
    }

    final end = _scroll.position.maxScrollExtent;

    // Jump when the OS asks for reduced motion; animate otherwise.
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(end);

      return;
    }

    await _scroll.animateTo(
      end,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _addDiary(String id) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add this to the diary?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep in Guide'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add to the diary'),
          ),
        ],
      ),
    );

    if (sure != true || !mounted) {
      return;
    }

    try {
      await PocketScope.of(context).saveDraft(id);
    } on Object {
      if (mounted) {
        setState(() => _error = _failed);
      }
    }
  }
}

class _GuideBubble extends StatelessWidget {
  const _GuideBubble({
    required this.note,
    required this.today,
    required this.onAdd,
  });

  final Note note;
  final DateTime today;
  final Future<void> Function()? onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ai = note.source == MessageSource.ai;

    // Person bubbles use the sheet tone so the olive edge reads on ivory.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ai ? scheme.primaryContainer : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: ai ? null : Border.all(color: scheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        // Merge the copy only; keep Add as its own control for VoiceOver.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ai)
                    const AiChip(AiLabel.reply, ground: ChipGround.petal)
                  else
                    Text(
                      note.author,
                      style: theme.textTheme.labelMedium!.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(note.body, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 4),
                  Text(
                    formatWhen(note.when, today),
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (onAdd != null) ...[
              const SizedBox(height: 8),
              TextButton(
                style: flushButton,
                onPressed: onAdd,
                child: const Text('Add to the diary'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
