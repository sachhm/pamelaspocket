import 'package:flutter_test/flutter_test.dart';
import 'package:pocket/domain/enums.dart';
import 'package:pocket/domain/records.dart';
import 'package:pocket/domain/seed.dart';
import 'package:pocket/domain/summary.dart';

final _words = RegExp(r"[A-Za-z’']+");

DiaryEntry _entry(String body, EntryKind kind, int hour) {
  return DiaryEntry(
    id: 'e-$hour',
    kind: kind,
    body: body,
    authorName: 'Jordan',
    authorRole: Role.staff,
    when: When(dayOffset: 0, hour: hour, minute: 0, seq: hour),
    attachment: Attachment.none,
    voice: VoiceNote.none,
    question: kind == EntryKind.question ? QuestionState.open : null,
    fileIds: const [],
  );
}

void main() {
  test('joins the three newest non-question bodies, newest first', () {
    final entries = [
      _entry('Oldest note.', EntryKind.general, 7),
      _entry('Second note.', EntryKind.mood, 8),
      _entry('Is the cushion here?', EntryKind.question, 12),
      _entry('Third note.', EntryKind.important, 9),
      _entry('Newest   note.', EntryKind.moment, 10),
    ];

    expect(summariseDiary(entries), 'Newest note. Third note. Second note.');
  });

  test('newest means last written, even at an earlier clock time', () {
    final seeded = _entry('Seeded at noon.', EntryKind.general, 12);
    const morning = When(dayOffset: 0, hour: 7, minute: 0, seq: 21);
    final written = DiaryEntry(
      id: 'e-new',
      kind: EntryKind.general,
      body: 'Written at seven.',
      authorName: 'Alex',
      authorRole: Role.owner,
      when: morning,
      attachment: Attachment.none,
      voice: VoiceNote.none,
      question: null,
      fileIds: const [],
    );

    expect(summariseDiary([seeded, written]), startsWith('Written at seven.'));
  });

  test('adds no word that was not in the entries', () {
    final entries = createSeed().entries;
    final source = entries.map((entry) => entry.body).join(' ');
    final allowed = _words.allMatches(source).map((m) => m[0]).toSet();

    final summary = summariseDiary(entries);
    final used = _words.allMatches(summary).map((m) => m[0]);

    expect(used, everyElement(isIn(allowed)));
    expect(summary, isNot(contains('cushion')));
  });

  test('an empty diary says so', () {
    expect(summariseDiary(const []), 'No notes yet.');
  });

  test('report summary is the first two sentences', () {
    const original =
        'First sentence here. Second sentence here. Third stays out.';

    expect(
      summariseReport(original),
      'First sentence here. Second sentence here.',
    );
    expect(original, contains('Third stays out.'));
  });

  test('a short report returns the trimmed original', () {
    expect(summariseReport('  One line only.  '), 'One line only.');
  });
}
