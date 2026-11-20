import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/enums.dart';
import '../../domain/records.dart';
import '../../domain/story.dart';
import '../../domain/time.dart';
import '../../session/pocket_scope.dart';
import '../../theme/pocket_theme.dart';
import '../../ui/ai_chip.dart';
import '../../ui/announced.dart';
import '../../ui/entry_row.dart';
import '../../ui/flush_button.dart';
import '../../ui/pamela_header.dart';
import '../../ui/paper_motion.dart';
import '../../ui/paths.dart';
import '../../ui/section_block.dart';
import '../../ui/shell_cover.dart';

const _end = 24.0;
const _edge = 4.0;

/// Home after sign-in. Order from 00-product:
///
///   ┌──────────────────────────────┐
///   │ (P) Pamela                   │  large title, scrolls away
///   │ ░ Handover      • AI summary │  petal card
///   │ ▓ Next visit                 │  sand band
///   │ ▌ 1 open question            │  bronze edge
///   │ ─────────                    │
///   │ Important                    │  list on ivory
///   │ Today                        │
///   └──────────────────────────────┘
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = PocketScope.of(context);
    final state = scope.state;
    final actor = scope.actor;

    if (state == null || actor == null) {
      return const SizedBox.shrink();
    }

    final open = _sorted(state.entries.where(_isOpen));
    final important = _sorted(
      state.entries.where((e) => e.kind == EntryKind.important),
    );
    final today = _sorted(
      state.entries.where(
        (e) =>
            e.when.dayOffset == 0 &&
            e.kind != EntryKind.important &&
            !_isOpen(e),
      ),
    );

    final storyCue =
        actor.role == Role.owner &&
        showStoryCue(state.prompts, state.storyDismissed);
    final emptyLife = emptyLifeCount(state.prompts);

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, _end),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: PamelaHeader(name: state.recipient.name),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _HandoverCard(state: state, refreshing: scope.refreshing),
        ),

        if (storyCue)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Continue Pamela’s story · $emptyLife left',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              trailing: IconButton(
                tooltip: 'Dismiss',
                onPressed: scope.dismissStory,
                icon: const Icon(Icons.close),
              ),
              onTap: () =>
                  context.push(Paths.askFor(nextAsk(state.prompts).id)),
            ),
          ),

        SectionBlock(
          tone: SectionTone.note,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Heading('Next visit'),
              const SizedBox(height: 12),
              Text(
                state.nextVisit,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (actor.role != Role.staff) ...[
                for (final item in _upcoming(state.appointments).take(2)) ...[
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      item.reason,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    subtitle: Text(
                      '${formatWhen(item.when, DateTime.now())} · ${item.place}',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    onTap: () => context.push(Paths.appointmentOf(item.id)),
                  ),
                ],
              ],
            ],
          ),
        ),

        if (open.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
            child: _QuestionStrip(questions: open, role: actor.role),
          ),

        if (important.isNotEmpty)
          SectionBlock(
            tone: SectionTone.list,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Heading('Important'),
                _Rows(entries: important),
              ],
            ),
          ),

        SectionBlock(
          tone: SectionTone.list,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Heading('Today'),
              if (today.isEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Nothing written yet today.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ] else
                _Rows(entries: today),
            ],
          ),
        ),
      ],
    );
  }

  static bool _isOpen(DiaryEntry entry) {
    return entry.kind == EntryKind.question &&
        entry.question == QuestionState.open;
  }

  // Newest written first.
  static List<DiaryEntry> _sorted(Iterable<DiaryEntry> entries) {
    return entries.toList()..sort((a, b) => compareWritten(b.when, a.when));
  }

  // Soonest upcoming appointments for owner and family.
  static List<Appointment> _upcoming(List<Appointment> items) {
    return items.where((a) => a.when.dayOffset >= 0).toList()
      ..sort((a, b) => compareWhen(a.when, b.when));
  }
}

/// The note just saved. It waits under the composer, then settles
/// as that page leaves. Every other row is already on the paper.
Widget _landed(BuildContext context, DiaryEntry entry, Widget child) {
  if (entry.id != PocketScope.of(context).addedEntryId) {
    return child;
  }

  final covered = ShellCover.shadeOf(context) == ShellShade.covered;

  return PaperSlip(
    key: ValueKey<String>('land-${entry.id}'),
    phase: covered ? SlipPhase.waiting : SlipPhase.settling,
    child: child,
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

/// Petal card. The seeded text is Alex's ("From Alex", no chip); after the
/// first refresh it is the model's ("AI summary", "Updated 9:40").
class _HandoverCard extends StatelessWidget {
  const _HandoverCard({required this.state, required this.refreshing});

  final PocketState state;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final by = state.handoverBy;
    final ai = by.source == HandoverSource.ai;

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),

        // Label, chip, paragraph, and meta read as one node.
        child: MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Handover', style: theme.textTheme.titleLarge),
                  // The chip arrives with the rewritten letter, not before it.
                  InkSwap(
                    token: ai ? 'model' : 'person',
                    child: ai
                        ? const AiChip(
                            AiLabel.summary,
                            ground: ChipGround.petal,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InkSwap(
                token: state.handover,
                child: Text(state.handover, style: PocketTheme.handover),
              ),
              const SizedBox(height: 12),
              _metaLine(theme, ai),
            ],
          ),
        ),
      ),
    );
  }

  // Only the start of a refresh is spoken; "Update saved" already was.
  Widget _metaLine(ThemeData theme, bool ai) {
    final meta = _meta(ai);
    final line = Text(
      meta,
      style: theme.textTheme.bodyMedium!.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );

    final shown = refreshing ? Announced(text: meta, child: line) : line;

    return InkSwap(token: meta, child: shown);
  }

  // The summary is as fresh as the newest note it was built from.
  String _meta(bool ai) {
    if (refreshing) {
      return 'Updating…';
    }

    if (!ai) {
      return 'From ${state.handoverBy.name}';
    }

    final notes = state.entries.where((e) => e.kind != EntryKind.question);

    if (notes.isEmpty) {
      return 'Updated';
    }

    final newest = notes.reduce(
      (a, b) => compareWritten(a.when, b.when) >= 0 ? a : b,
    );

    return 'Updated ${formatClock(newest.when)}';
  }
}

/// Ivory strip with a bronze edge. The owner resolves from here.
class _QuestionStrip extends StatelessWidget {
  const _QuestionStrip({required this.questions, required this.role});

  final List<DiaryEntry> questions;
  final Role role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = questions.length;
    final noun = count == 1 ? 'question' : 'questions';

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.colorScheme.tertiary, width: _edge),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Heading('$count open $noun'),
            for (final question in questions)
              _landed(
                context,
                question,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EntryRow(
                      entry: question,
                      onTap: () => context.push(Paths.entryOf(question.id)),
                    ),
                    if (role == Role.owner)
                      TextButton(
                        style: flushButton,
                        onPressed: () => PocketScope.of(
                          context,
                        ).resolveQuestion(question.id),
                        child: const Text('Mark resolved'),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Plain rows with a hairline between them.
class _Rows extends StatelessWidget {
  const _Rows({required this.entries});

  final List<DiaryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (i, entry) in entries.indexed) ...[
          if (i > 0) const Divider(),
          _landed(
            context,
            entry,
            EntryRow(
              entry: entry,
              onTap: () => context.push(Paths.entryOf(entry.id)),
            ),
          ),
        ],
      ],
    );
  }
}
