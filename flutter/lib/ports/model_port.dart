import '../domain/records.dart';

/// Language calls. Takes diary entries only, so guide notes cannot reach the
/// handover.
abstract interface class ModelPort {
  Future<String> summariseDiary(List<DiaryEntry> entries);

  /// First two sentences of the pasted report text.
  Future<String> summariseReport(String original);

  /// A quote from the card or the diary, or "No pattern yet.". No causes.
  Future<String> suggestPattern(WorkCard card, List<DiaryEntry> entries);

  Future<Answer> answerCare(String text, List<DiaryEntry> entries);

  /// One of three fixed guide lines. [spokenCount] is person notes so far.
  Future<String> guideReply(int spokenCount);
}
