import 'package:flutter/material.dart';

import '../../domain/time.dart';
import '../../session/pocket_scope.dart';
import '../../ui/ai_chip.dart';
import '../../ui/stored_photo.dart';

/// One report. Summary, note, original, then the file. No edit.
class ReportLeaf extends StatelessWidget {
  const ReportLeaf({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final scope = PocketScope.of(context);
    final state = scope.state;
    final theme = Theme.of(context);

    if (state == null) {
      return const SizedBox.shrink();
    }

    final report = state.reports.where((r) => r.id == id).firstOrNull;

    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report')),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('That report is not in the folder.'),
        ),
      );
    }

    final muted = theme.textTheme.bodyMedium!.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Scaffold(
      appBar: AppBar(title: Text(report.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${report.author} · ${formatWhen(report.when, DateTime.now())}',
            style: muted,
          ),
          const SizedBox(height: 16),
          // Chip + paragraph read as one AI block for VoiceOver / TalkBack.
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AiChip(AiLabel.summary),
                const SizedBox(height: 8),
                Text(report.summary, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
          if (report.note.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Note', style: muted),
            const SizedBox(height: 8),
            Text(report.note, style: theme.textTheme.bodyLarge),
          ],
          if (report.original.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Original', style: muted),
            const SizedBox(height: 8),
            Text(report.original, style: theme.textTheme.bodyLarge),
          ],
          if (report.fileId case final fileId?) ...[
            const SizedBox(height: 24),
            StoredPhoto(id: fileId, label: 'Attached file'),
          ],
        ],
      ),
    );
  }
}
