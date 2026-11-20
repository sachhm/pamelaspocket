import 'records.dart';
import 'time.dart';

const noPattern = 'No pattern yet.';

// Two notes about the same situation make a pattern; one is an anecdote.
const _enough = 2;

// Shorter words ("it", "time", "uses") tie unrelated notes together.
const _keyLength = 5;

// Long but common words that say nothing about the situation.
const _common = {'becomes', 'someone', 'their', 'there', 'where', 'which'};

final _word = RegExp(r"[a-z']+");
final _sentenceEnd = RegExp(r'(?<=[.!?])\s+');

/// The local What Works suggestion. Copies one sentence from Pamela's notes,
/// after the situation it belongs to, and invents nothing.
///
/// ```text
/// notes = the card's observations, newest first,
///       + diary lines that share a key word with the situation
/// fewer than two → "No pattern yet."
/// otherwise      → "<situation> <first sentence of the newest note>"
/// ```
String suggestPattern(WorkCard card, List<DiaryEntry> entries) {
  final keys = _words(
    card.situation,
  ).where((w) => w.length >= _keyLength && !_common.contains(w)).toSet();
  final diary = entries.where((e) => _words(e.body).any(keys.contains)).toList()
    ..sort((a, b) => compareWritten(b.when, a.when));
  final notes = [...card.observations.reversed, for (final e in diary) e.body];

  if (notes.length < _enough) {
    return noPattern;
  }

  return '${card.situation} ${notes.first.split(_sentenceEnd).first}';
}

Iterable<String> _words(String text) {
  return _word.allMatches(text.toLowerCase()).map((m) => m.group(0)!);
}
