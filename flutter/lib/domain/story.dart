import 'enums.dart';
import 'records.dart';

/// The prompt "Continue the story" opens: the first unanswered one, or the
/// first of all when every prompt has an answer.
Prompt nextAsk(List<Prompt> prompts) {
  return prompts.firstWhere(
    (p) => p.answer.trim().isEmpty,
    orElse: () => prompts.first,
  );
}

/// A life prompt earns a place on the timeline once it has a year or an
/// answer.
bool onTimeline(Prompt prompt) {
  return prompt.year.isNotEmpty || prompt.answer.trim().isNotEmpty;
}

/// Life prompts only, in seed order — onboarding walks this list.
List<Prompt> lifePrompts(List<Prompt> prompts) {
  return [for (final p in prompts) if (p.section == StorySection.life) p];
}

/// How many life prompts still need an answer.
int emptyLifeCount(List<Prompt> prompts) {
  return lifePrompts(
    prompts,
  ).where((p) => p.answer.trim().isEmpty).length;
}

/// Today’s story row: empty life left, and dismiss has not frozen this count.
bool showStoryCue(List<Prompt> prompts, int storyDismissed) {
  final empty = emptyLifeCount(prompts);

  return empty > 0 && empty != storyDismissed;
}
