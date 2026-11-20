import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/enums.dart';
import '../../domain/records.dart';
import '../../domain/time.dart';
import '../../session/pocket_scope.dart';
import '../../ui/entry_label.dart';
import '../../ui/flush_button.dart';
import '../../ui/paths.dart';
import '../../ui/section_block.dart';

/// Household board: status, moment, recent, appointments, requests.
///
///   How Pamela has been
///   A lovely moment
///   Recent updates (3)
///   Coming up
///   Where help would matter
class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = PocketScope.of(context);
    final actor = scope.actor;
    final state = scope.state;
    final theme = Theme.of(context);

    if (actor == null || state == null) {
      return const SizedBox.shrink();
    }

    final today = DateTime.now();
    final recent = [...state.entries]
      ..sort((a, b) => compareWritten(b.when, a.when));
    final top = recent.take(3).toList();
    final moments = state.entries.where((e) => e.kind == EntryKind.moment);
    final moment = moments.isEmpty
        ? null
        : (moments.toList()..sort((a, b) => compareWritten(b.when, a.when)))
              .first;
    final upcoming =
        state.appointments.where((a) => a.when.dayOffset >= 0).toList()
          ..sort((a, b) => compareWhen(a.when, b.when));
    final owner = actor.role == Role.owner;

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      children: [
        SectionBlock(
          tone: SectionTone.note,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Heading('How Pamela has been'),
              const SizedBox(height: 12),
              Text(state.familyStatus, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),

        if (moment != null)
          SectionBlock(
            tone: SectionTone.note,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Heading('A lovely moment'),
                const SizedBox(height: 12),
                Text(moment.body, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 4),
                Text(
                  moment.authorName,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

        SectionBlock(
          tone: SectionTone.list,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Heading('Recent updates'),
              for (final entry in top) ...[
                const SizedBox(height: 12),
                Text(entry.body, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 4),
                Text(
                  '${entryLabel(entry.kind)} · ${entry.authorName} · '
                  '${formatWhen(entry.when, today)}',
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),

        SectionBlock(
          tone: SectionTone.list,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Action under the heading so large text never shares one row.
              const _Heading('Coming up'),
              TextButton(
                style: flushButton,
                onPressed: () => context.push(Paths.appointmentNew),
                child: const Text('Add an appointment'),
              ),
              for (final item in upcoming) ...[
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.reason, style: theme.textTheme.bodyLarge),
                  subtitle: Text(
                    '${formatWhen(item.when, today)} · ${item.place}\n'
                    '${item.transport}'
                    '${item.reminder == Reminder.on ? '\nReminder on' : ''}'
                    '${item.volunteer != null ? '\n${item.volunteer} can help' : ''}',
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.secondary,
                  ),
                  onTap: () => context.push(Paths.appointmentOf(item.id)),
                ),
              ],
            ],
          ),
        ),

        SectionBlock(
          tone: SectionTone.list,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Heading('Where help would matter'),
              if (owner)
                TextButton(
                  style: flushButton,
                  onPressed: () => context.push(Paths.request),
                  child: const Text('Ask for help'),
                ),
              for (final (index, request) in state.requests.indexed) ...[
                if (index > 0) const Divider(),
                const SizedBox(height: 12),
                _RequestRow(
                  request: request,
                  lead: owner ? _Lead.owner : _Lead.family,
                  onAccept: () => scope.acceptHelp(request.id),
                  onRemove: () => _remove(context, request.id),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Confirm first — same shape as removing a diary update.
  Future<void> _remove(BuildContext context, String id) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this request?'),
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

    if (sure != true || !context.mounted) {
      return;
    }

    await PocketScope.of(context).removeRequest(id);
  }
}

enum _Lead { owner, family }

/// One ask: merged copy, then separate I can help / Remove controls.
class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.request,
    required this.lead,
    required this.onAccept,
    required this.onRemove,
  });

  final HelpRequest request;
  final _Lead lead;
  final VoidCallback onAccept;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(request.text, style: theme.textTheme.bodyLarge),
              if (request.acceptedBy != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${request.acceptedBy} can help',
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (request.acceptedBy == null)
          TextButton(
            style: flushButton,
            onPressed: onAccept,
            child: const Text('I can help'),
          ),
        if (lead == _Lead.owner)
          TextButton(
            style: flushDanger,
            onPressed: onRemove,
            child: const Text('Remove'),
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
