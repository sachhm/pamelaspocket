import '../../domain/codec.dart';
import '../../domain/enums.dart';
import '../../domain/records.dart';
import '../../ports/model_port.dart';
import 'api_client.dart';

/// Model calls over `/v1/model/…`.
class HttpModel implements ModelPort {
  HttpModel(this._client);

  final ApiClient _client;

  @override
  Future<String> summariseDiary(List<DiaryEntry> entries) async {
    final body = await _client.post('/v1/model/handover', {
      'entries': [for (final e in entries) encodeEntry(e)],
    });

    return body['text']! as String;
  }

  @override
  Future<String> summariseReport(String original) async {
    final body = await _client.post('/v1/model/report', {
      'original': original,
    });

    return body['text']! as String;
  }

  @override
  Future<String> suggestPattern(WorkCard card, List<DiaryEntry> entries) async {
    final body = await _client.post('/v1/model/pattern', {
      'card': encodeWork(card),
      'entries': [for (final e in entries) encodeEntry(e)],
    });

    return body['text']! as String;
  }

  @override
  Future<Answer> answerCare(String text, List<DiaryEntry> entries) async {
    final body = await _client.post('/v1/model/care', {
      'text': text,
      'entries': [for (final e in entries) encodeEntry(e)],
    });

    return Answer(
      known: Known.values.byName(body['known']! as String),
      body: body['body']! as String,
    );
  }

  @override
  Future<String> guideReply(int spokenCount) async {
    final body = await _client.post('/v1/model/guide', {
      'spoken': spokenCount,
    });

    return body['text']! as String;
  }
}
