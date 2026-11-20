import 'package:flutter_test/flutter_test.dart';
import 'package:pocket/domain/chat.dart';
import 'package:pocket/domain/enums.dart';
import 'package:pocket/domain/seed.dart';

void main() {
  final seed = createSeed();

  test('breakfast cue answers from the notes', () {
    final answer = answerCare(
      'What does she usually have for breakfast?',
      seed.entries,
    );

    expect(answer.known, Known.yes);
    expect(answer.body.toLowerCase(), contains('porridge'));
  });

  test('spare clothes cue', () {
    final answer = answerCare('Where are the spare clothes?', seed.entries);

    expect(answer.known, Known.yes);
    expect(answer.body.toLowerCase(), contains('hall cupboard'));
  });

  test('upset phone cue', () {
    final answer = answerCare(
      'She got upset by a phone. What helps?',
      seed.entries,
    );

    expect(answer.known, Known.yes);
    expect(answer.body.toLowerCase(), contains('step outside'));
  });

  test('eat cue uses today’s meal note', () {
    final answer = answerCare('Has she eaten?', seed.entries);

    expect(answer.known, Known.yes);
    expect(answer.body, contains('Porridge'));
  });

  test('last visit cue uses a prior entry', () {
    final answer = answerCare(
      'What happened on the previous visit?',
      seed.entries,
    );

    expect(answer.known, Known.yes);
    expect(answer.body, contains('Sam wrote:'));
    expect(answer.body, contains('GP visit'));
  });

  test('unknown cue says it does not have that', () {
    final answer = answerCare('What is her dose?', seed.entries);

    expect(answer.known, Known.no);
    expect(answer.body, "I don't have that in Pamela's notes.");
  });

  test('guide replies rotate and invent no medicine', () {
    final first = guideReply(0);
    final second = guideReply(1);
    final fourth = guideReply(3);

    expect(first, isNot(equals(second)));
    expect(fourth, first);
    for (final line in [first, second, guideReply(2)]) {
      expect(line.toLowerCase(), isNot(contains('dose')));
      expect(line.toLowerCase(), isNot(contains('mg')));
    }
  });

  test('a handover draft is marked for the diary', () {
    expect(diaryDraftAsk, isNotEmpty);
    expect(handoverDraft.toLowerCase(), contains('pamela'));
  });
}
