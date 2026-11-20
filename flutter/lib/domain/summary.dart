import 'enums.dart';
import 'records.dart';
import 'time.dart';

const _recentNotes = 3;
const _reportSentences = 2;
final _space = RegExp(r'\s+');
// Split after a period so "A. B. C." yields three sentences.
final _sentenceBreak = RegExp(r'(?<=\.)\s+');

/// The local handover: the three newest notes that are not questions, joined
/// as written. Questions have their own strip. It adds no word of its own.
String summariseDiary(List<DiaryEntry> entries) {
  final recent =
      entries.where((entry) => entry.kind != EntryKind.question).toList()
        ..sort((a, b) => compareWritten(b.when, a.when));

  if (recent.isEmpty) {
    return 'No notes yet.';
  }

  return recent
      .take(_recentNotes)
      .map((entry) => entry.body.replaceAll(_space, ' ').trim())
      .join(' ');
}

/// First two sentences of [original]. Fewer sentences return the trimmed text.
String summariseReport(String original) {
  final trimmed = original.trim();

  if (trimmed.isEmpty) {
    return trimmed;
  }

  final sentences = trimmed
      .split(_sentenceBreak)
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .take(_reportSentences)
      .toList();

  if (sentences.isEmpty) {
    return trimmed;
  }

  return sentences.join(' ');
}
