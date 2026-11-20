import 'enums.dart';
import 'records.dart';

/// Starter chips on Pocket Guide. Tapping one fills the composer.
const guideHardDay = 'A hard day';
const guideHandover = 'Draft a handover';
const guideFamily = 'Draft a family note';

const guideStarters = [guideHardDay, guideHandover, guideFamily];

/// Stored on an AI guide note so the leaf can offer "Add to the diary".
const diaryDraftAsk = 'handover-draft';

/// The draft body when someone asks to draft a handover. Plain facts only.
const handoverDraft =
    'Pamela had a gentle morning. She settled after a walk to the letterbox.';

const _unknown = "I don't have that in Pamela's notes.";
const _noMeal = "I don't have that in today's notes.";
const _noPrior = "I don't have a note from the previous visit.";

// \bate\b so "watered" is not a meal note.
final _meal = RegExp(
  r'porrid|breakfast|lunch|dinner|\bate\b|tea',
  caseSensitive: false,
);

const _guideReplies = [
  "That sounds like a heavy moment. You don't have to solve all of it tonight.",
  "You're allowed to find this hard. What would make the next hour a little easier?",
  'Thank you for saying it plainly. None of this is added to the shared diary.',
];

Answer _yes(String body) => Answer(known: Known.yes, body: body);

Answer _no(String body) => Answer(known: Known.no, body: body);

/// Care chat: repeats Pamela's notes. Missing notes say so in plain language.
Answer answerCare(String text, List<DiaryEntry> entries) {
  final question = text.toLowerCase();

  if (question.contains('breakfast') || question.contains('porridge')) {
    return _yes('Pamela usually has porridge with honey, and tea with milk.');
  }

  if (question.contains('spare') || question.contains('clothes')) {
    return _yes('Spare clothes are in the hall cupboard, on the second shelf.');
  }

  if (question.contains('upset') || question.contains('phone')) {
    return _yes(
      'Step outside to take the call, and tell her calmly before you leave. '
      'Taking the call in front of her has not helped.',
    );
  }

  if (question.contains('eaten') || question.contains('eat')) {
    final meal = entries
        .where((e) => e.when.dayOffset == 0 && _meal.hasMatch(e.body))
        .firstOrNull;

    if (meal == null) {
      return _no(_noMeal);
    }

    return _yes(meal.body);
  }

  if (question.contains('previous') || question.contains('last visit')) {
    final prior = entries.where((e) => e.when.dayOffset < 0).toList()
      ..sort((a, b) => b.when.dayOffset - a.when.dayOffset);

    if (prior.isEmpty) {
      return _no(_noPrior);
    }

    final note = prior.first;

    return _yes('${note.authorName} wrote: ${note.body}');
  }

  return _no(_unknown);
}

/// Rotates three fixed lines. None name a drug, a dose, or a diagnosis.
String guideReply(int spokenCount) {
  return _guideReplies[spokenCount % _guideReplies.length];
}

/// True when this AI guide note may be confirmed into the diary.
bool isDiaryDraft(Note note) {
  return note.thread == Thread.guide &&
      note.source == MessageSource.ai &&
      note.asked == diaryDraftAsk;
}
