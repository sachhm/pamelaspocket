import 'package:flutter/material.dart';

import '../domain/records.dart';
import '../domain/time.dart';
import 'entry_label.dart';

/// A plain diary row on ivory: the note, then kind, author, and time.
///
///   She hummed along to Vera Lynn…      ›
///   A lovely moment · Alex · 11:15 am
class EntryRow extends StatelessWidget {
  const EntryRow({super.key, required this.entry, required this.onTap});

  final DiaryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Today's rows show the time alone; older ones say which day.
    final when = entry.when.dayOffset == 0
        ? formatClock(entry.when)
        : formatWhen(entry.when, DateTime.now());

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        entry.body,
        style: theme.textTheme.bodyLarge,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${entryLabel(entry.kind)} · ${entry.authorName} · $when',
        style: theme.textTheme.bodyMedium!.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: theme.colorScheme.secondary),
      onTap: onTap,
    );
  }
}
