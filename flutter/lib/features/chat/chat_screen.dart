import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/enums.dart';
import '../../domain/records.dart';
import '../../domain/time.dart';
import '../../session/pocket_scope.dart';
import '../../ui/ai_chip.dart';
import '../../ui/announced.dart';
import '../../ui/busy_label.dart';
import '../../ui/field_error.dart';
import '../../ui/flush_button.dart';
import '../../ui/paper_motion.dart';
import '../../ui/paths.dart';

const _failed = 'The care service did not answer.';
const _checking = 'Checking Pamela’s notes…';

/// Care thread. Person on the right, AI on the left with the reply chip.
///
///   [Pocket Guide]                 ← owner and family
///   …bubbles…
///   Ask Alex or Chris              ← unknown AI, not yet sent
///   ┌ Ask about Pamela ──┐ [Send]
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
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

    if (actor == null || state == null) {
      return const SizedBox.shrink();
    }

    final notes = state.messages.where((n) => n.thread == Thread.care).toList()
      ..sort((a, b) => compareWritten(a.when, b.when));
    final household = actor.role != Role.staff;
    final empty = _draft.text.trim().isEmpty;

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scroll,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              if (household)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton(
                        style: flushButton,
                        onPressed: () => context.push(Paths.guide),
                        child: const Text('Pocket Guide'),
                      ),
                      Text(
                        'Private. Not part of the diary.',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

              FreshSlips(
                ids: [for (final note in notes) note.id],
                item: (id) {
                  final note = notes.firstWhere((n) => n.id == id);

                  return _Bubble(
                    note: note,
                    today: DateTime.now(),
                    sentLabel: _sentLabel(note, notes),
                    targets: _targets(state, actor),
                    onSendTo:
                        note.known == Known.no &&
                            note.escalation != Escalation.sent &&
                            actor.role != Role.owner
                        ? (name) => _sendTo(note.id, name)
                        : null,
                  );
                },
              ),

              if (_phase == Phase.busy) ...[
                const SizedBox(height: 12),
                Announced(
                  text: _checking,
                  child: Text(
                    _checking,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Bronze hairline separates the thread from the composer, like the tab bar.
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Theme.of(context).colorScheme.tertiary),
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
                            labelText: 'Ask about Pamela',
                          ),
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) {
                            if (!empty && _phase == Phase.idle) {
                              _send();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: !empty && _phase == Phase.idle
                            ? _send
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
    );
  }

  // Owner and family names, minus the person asking.
  List<String> _targets(PocketState state, Actor actor) {
    return [
      for (final person in state.people)
        if (person.role != Role.staff && person.name != actor.name) person.name,
    ];
  }

  // "Sent to Chris" from the follow-up note written by sendToPerson.
  String? _sentLabel(Note note, List<Note> notes) {
    if (note.escalation != Escalation.sent || note.asked == null) {
      return null;
    }

    final follow = notes.where(
      (n) =>
          n.source == MessageSource.person &&
          n.body.startsWith('Asked ') &&
          n.body.endsWith(': ${note.asked}'),
    );

    if (follow.isEmpty) {
      return 'Sent';
    }

    final body = follow.last.body;
    final name = body.substring(6, body.indexOf(':'));

    return 'Sent to $name';
  }

  Future<void> _send() async {
    final text = _draft.text;
    final scope = PocketScope.of(context);

    FocusScope.of(context).unfocus();
    setState(() {
      _phase = Phase.busy;
      _error = null;
    });

    try {
      await scope.sendChat(text);
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

  Future<void> _sendTo(String id, String name) async {
    try {
      await PocketScope.of(context).sendToPerson(id, name);
    } on Object {
      if (mounted) {
        setState(() => _error = _failed);
      }
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
}

/// One care bubble. AI is petal on the left; person is ivory on the right.
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.note,
    required this.today,
    required this.sentLabel,
    required this.targets,
    required this.onSendTo,
  });

  final Note note;
  final DateTime today;
  final String? sentLabel;
  final List<String> targets;
  final Future<void> Function(String name)? onSendTo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ai = note.source == MessageSource.ai;
    final time = formatWhen(note.when, today);

    // Person bubbles use the sheet tone so the olive edge reads on ivory.
    final bubble = DecoratedBox(
      decoration: BoxDecoration(
        color: ai ? scheme.primaryContainer : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: ai ? null : Border.all(color: scheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        // Merge the copy only; keep Ask as its own control for VoiceOver.
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
                    time,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (sentLabel != null)
                    Text(
                      sentLabel!,
                      style: theme.textTheme.labelMedium!.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (onSendTo != null && targets.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                style: flushButton,
                onPressed: () => _pick(context),
                child: Text('Ask ${targets.join(' or ')}'),
              ),
            ],
          ],
        ),
      ),
    );

    return Align(
      alignment: ai
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
        ),
        child: bubble,
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final name = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final target in targets)
              ListTile(
                title: Text(target),
                onTap: () => Navigator.pop(context, target),
              ),
          ],
        ),
      ),
    );

    if (name != null) {
      await onSendTo!(name);
    }
  }
}
