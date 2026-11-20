import 'package:flutter_test/flutter_test.dart';
import 'package:pocket/adapters/http/api_client.dart';
import 'package:pocket/adapters/http/http_auth.dart';
import 'package:pocket/adapters/http/http_files.dart';
import 'package:pocket/adapters/http/http_model.dart';
import 'package:pocket/adapters/http/http_records.dart';
import 'package:pocket/adapters/local/local_auth.dart';
import 'package:pocket/care/compose.dart';
import 'package:pocket/care/desk.dart';
import 'package:pocket/domain/auth.dart';
import 'package:pocket/domain/codec.dart';
import 'package:pocket/domain/commands.dart';
import 'package:pocket/domain/enums.dart';
import 'package:pocket/domain/records.dart';
import 'package:pocket/domain/seed.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records paths and holds a session so desk gates succeed after sign-in.
class _FakeClient implements ApiClient {
  _FakeClient(this.paths);

  final List<String> paths;
  final state = createSeed();
  Actor? session;

  @override
  Future<Json> get(String path) async {
    paths.add(path);

    if (path == '/v1/auth/session') {
      return {'actor': encodeActor(session)};
    }

    if (path == '/v1/records') {
      return encodeState(state);
    }

    if (path.startsWith('/v1/files/')) {
      return {};
    }

    return {};
  }

  @override
  Future<Json> post(String path, Json body) async {
    paths.add(path);

    if (path == '/v1/auth/sign-in' || path == '/v1/auth/sign-up') {
      session = actorFor(Role.owner);

      return {
        'result': SignInResult.ok.name,
        'actor': encodeActor(session),
      };
    }

    if (path == '/v1/auth/sign-out') {
      session = null;

      return {};
    }

    if (path == '/v1/auth/preview') {
      session = actorFor(Role.owner);

      return {'actor': encodeActor(session)};
    }

    if (path == '/v1/records/commands') {
      return encodeState(state);
    }

    if (path == '/v1/model/pattern') {
      return {'text': 'No pattern yet.'};
    }

    if (path == '/v1/model/handover' ||
        path == '/v1/model/report' ||
        path == '/v1/model/guide') {
      return {'text': 'ok'};
    }

    if (path == '/v1/model/care') {
      return {'known': Known.yes.name, 'body': 'ok'};
    }

    if (path == '/v1/files') {
      return {
        'id': 'file-1',
        'kind': body['kind'],
        'label': body['label'],
      };
    }

    return {};
  }
}

CareDesk _httpDesk(ApiClient client) {
  return CareDesk(
    HttpAuth(client),
    HttpRecords(client),
    HttpModel(client),
    HttpFiles(client),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('empty API root stays on local adapters', () async {
    expect(usesHttp(''), isFalse);
    expect(usesHttp('https://api.example/'), isTrue);
    expect(normalizeApiRoot('https://api.example/'), 'https://api.example');

    final prefs = await SharedPreferences.getInstance();
    final desk = composeDesk(prefs, apiUrl: '');
    await desk.load();

    final outcome = await desk.signIn(Role.owner, ownerEmail, demoPassword);

    expect(outcome.result, SignInResult.ok);
    expect(outcome.actor?.name, 'Alex');
    // Local auth wrote the actor key — proves we did not use HTTP.
    expect(prefs.getString(actorKey), isNotNull);
  });

  test('define value selects HTTP and hits sign-in plus entry.add', () async {
    final paths = <String>[];
    final client = _FakeClient(paths);
    final desk = composeDesk(
      await SharedPreferences.getInstance(),
      apiUrl: 'https://api.example/',
      client: client,
    );

    final outcome = await desk.signIn(Role.owner, ownerEmail, demoPassword);
    expect(outcome.result, SignInResult.ok);
    expect(paths, contains('/v1/auth/sign-in'));

    final next = await desk.addEntry((
      kind: EntryKind.general,
      body: 'Tea after the garden.',
      attachment: Attachment.none,
      voice: VoiceNote.none,
      fileIds: const [],
    ));

    expect(next, isNotNull);
    expect(paths, contains('/v1/records/commands'));
  });

  test('HTTP paths cover sign-up, pattern, and member.set', () async {
    final paths = <String>[];
    final kinds = <String>[];
    final client = _RecordingKinds(_FakeClient(paths), kinds);
    final desk = _httpDesk(client);

    await desk.signUp(Role.owner, ownerEmail, demoPassword);
    expect(paths, contains('/v1/auth/sign-up'));

    await desk.suggestPattern('phone-calls');
    expect(paths, contains('/v1/model/pattern'));

    await desk.setMember('Chris', AccessState.revoked);
    expect(kinds, contains('member.set'));
    expect(paths, contains('/v1/records/commands'));
  });

  test('encodeCommand names match the architecture contract', () {
    expect(
      encodeCommand(const AccessSet(AccessState.revoked))['kind'],
      'access.set',
    );
    expect(
      encodeCommand(const MemberSet('Chris', AccessState.revoked))['kind'],
      'member.set',
    );
    expect(
      encodeCommand(const OnboardingSet(Onboarding.done))['kind'],
      'onboarding.set',
    );
  });
}

/// Wraps a client and records command kinds posted to records/commands.
class _RecordingKinds implements ApiClient {
  _RecordingKinds(this._inner, this.kinds);

  final ApiClient _inner;
  final List<String> kinds;

  @override
  Future<Json> get(String path) => _inner.get(path);

  @override
  Future<Json> post(String path, Json body) async {
    if (path == '/v1/records/commands') {
      final command = body['command']! as Json;
      kinds.add(command['kind']! as String);
    }

    return _inner.post(path, body);
  }
}
