import '../../domain/chat.dart' as chat;
import '../../domain/pattern.dart' as pattern;
import '../../domain/records.dart';
import '../../domain/summary.dart' as summary;
import '../../ports/model_port.dart';

/// On-device stand-in for the model. Repeats Pamela's notes; invents nothing.
class LocalModel implements ModelPort {
  const LocalModel();

  @override
  Future<String> summariseDiary(List<DiaryEntry> entries) async {
    return summary.summariseDiary(entries);
  }

  @override
  Future<String> summariseReport(String original) async {
    return summary.summariseReport(original);
  }

  @override
  Future<String> suggestPattern(WorkCard card, List<DiaryEntry> entries) async {
    return pattern.suggestPattern(card, entries);
  }

  @override
  Future<Answer> answerCare(String text, List<DiaryEntry> entries) async {
    return chat.answerCare(text, entries);
  }

  @override
  Future<String> guideReply(int spokenCount) async {
    return chat.guideReply(spokenCount);
  }
}
