import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/enums.dart';
import '../../domain/records.dart';
import '../../domain/story.dart';
import '../../session/pocket_scope.dart';
import '../../ui/paths.dart';
import '../../ui/section_block.dart';
import '../../ui/stored_photo.dart';

// Room for "1948" beside each dated life row; larger text scales it down.
const _yearWidth = 64.0;

/// Whether a row opens its prompt for editing. Staff read only.
enum _Edit { open, readOnly }

/// Pamela's story on one scroll: four headings, not four tabs.
///
///   Life                     1948  Where did Pamela grow up?   ›
///   Continue the story             Fremantle, in a weatherboard…
///   Personality              What makes her laugh?             ›
///   Routines                 What does a good day look like?   ›
///   What works               Becomes upset when someone…       ›
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = PocketScope.of(context);
    final state = scope.state;
    final actor = scope.actor;

    if (state == null || actor == null) {
      return const SizedBox.shrink();
    }

    final edit = actor.role == Role.staff ? _Edit.readOnly : _Edit.open;
    final prompts = state.prompts;

    // Life keeps dated or answered prompts; the others list answers only.
    final life = prompts.where(
      (p) => p.section == StorySection.life && onTimeline(p),
    );
    List<Prompt> answered(StorySection section) {
      return prompts
          .where((p) => p.section == section && p.answer.trim().isNotEmpty)
          .toList();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      children: [
        SectionBlock(
          tone: SectionTone.list,
          place: SectionPlace.first,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Heading('Life'),
              _Rows([for (final p in life) _PromptRow(p, edit)]),
            ],
          ),
        ),
        SectionBlock(
          tone: SectionTone.list,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Heading('Personality'),
              _Rows([
                for (final p in answered(StorySection.personality))
                  _PromptRow(p, edit),
              ]),
            ],
          ),
        ),
        SectionBlock(
          tone: SectionTone.list,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Heading('Routines'),
              _Rows([
                for (final p in answered(StorySection.routines))
                  _PromptRow(p, edit),
              ]),
            ],
          ),
        ),
        SectionBlock(
          tone: SectionTone.list,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Heading('What works'),
              _Rows([for (final card in state.works) _WorkRow(card)]),
            ],
          ),
        ),
      ],
    );
  }
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

/// Rows with a hairline between them; one sentence when there are none.
class _Rows extends StatelessWidget {
  const _Rows(this.rows);

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          'Nothing written here yet.',
          style: theme.textTheme.bodyLarge!.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final (i, row) in rows.indexed) ...[
          if (i > 0) const Divider(),
          row,
        ],
      ],
    );
  }
}

/// A ListTile like Today: ask, answer, optional year and photo, chevron
/// when the person may edit. An empty year leaves no gutter.
class _PromptRow extends StatelessWidget {
  const _PromptRow(this.prompt, this.edit);

  final Prompt prompt;
  final _Edit edit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final ink = theme.colorScheme.onSurfaceVariant;
    final photo = prompt.photoId;
    final empty = prompt.answer.trim().isEmpty;
    final year = prompt.year.trim();
    final open = edit == _Edit.open;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      isThreeLine: true,
      // Dated life rows only; undated ones sit flush with the page edge.
      leading: year.isEmpty
          ? null
          : SizedBox(
              width: _yearWidth,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(year, style: text.titleLarge),
              ),
            ),
      title: Text(prompt.ask, style: text.labelMedium!.copyWith(color: ink)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            empty ? 'Not answered yet.' : prompt.answer,
            style: empty
                ? text.bodyLarge!.copyWith(color: ink)
                : text.bodyLarge,
          ),
          if (photo != null) ...[
            const SizedBox(height: 12),
            StoredPhoto(
              key: ValueKey(photo),
              id: photo,
              label: 'Photo with this memory',
              size: PhotoSize.thumb,
            ),
          ],
        ],
      ),
      trailing: open
          ? Icon(Icons.chevron_right, color: theme.colorScheme.secondary)
          : null,
      onTap: open ? () => context.push(Paths.askFor(prompt.id)) : null,
    );
  }
}

/// Situation, then what helps. Every role may open the card.
class _WorkRow extends StatelessWidget {
  const _WorkRow(this.card);

  final WorkCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(card.situation, style: theme.textTheme.bodyLarge),
      subtitle: Text(
        card.helps,
        style: theme.textTheme.bodyMedium!.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: theme.colorScheme.secondary),
      onTap: () => context.push(Paths.worksOf(card.id)),
    );
  }
}
