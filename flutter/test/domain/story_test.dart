import 'package:flutter_test/flutter_test.dart';
import 'package:pocket/domain/apply.dart';
import 'package:pocket/domain/commands.dart';
import 'package:pocket/domain/seed.dart';
import 'package:pocket/domain/story.dart';

void main() {
  final seed = createSeed();

  test('every prompt answered: the story continues from the first', () {
    expect(nextAsk(seed.prompts).id, 'grew-up');
  });

  test('the first empty prompt is next', () {
    final next = apply(seed, const AnswerSave('music', ''));

    expect(nextAsk(next.prompts).id, 'music');
  });

  test('answer.save keeps a photo on the prompt', () {
    final next = apply(
      seed,
      const AnswerSave('work', 'Teacher.', photoId: 'photo-1'),
    );
    final work = next.prompts.firstWhere((p) => p.id == 'work');

    expect(work.answer, 'Teacher.');
    expect(work.photoId, 'photo-1');
    expect(work.year, '1966');
  });
}
