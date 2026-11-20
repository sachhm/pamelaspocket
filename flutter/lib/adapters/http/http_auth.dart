import '../../domain/codec.dart';
import '../../domain/enums.dart';
import '../../domain/records.dart';
import '../../ports/auth_port.dart';
import 'api_client.dart';

/// Auth against `/v1/auth/…`.
class HttpAuth implements AuthPort {
  HttpAuth(this._client);

  final ApiClient _client;

  @override
  Future<Actor?> current() async {
    final body = await _client.get('/v1/auth/session');

    return decodeActor(body['actor']);
  }

  @override
  Future<AuthOutcome> signIn(Role role, String email, String password) {
    return _authPost('/v1/auth/sign-in', {
      'role': role.name,
      'email': email,
      'password': password,
    });
  }

  @override
  Future<AuthOutcome> signUp(Role role, String email, String password) {
    return _authPost('/v1/auth/sign-up', {
      'role': role.name,
      'email': email,
      'password': password,
    });
  }

  @override
  Future<StaffOutcome> enterStaff(
    String pin,
    AccessState access,
    String name,
  ) async {
    final body = await _client.post('/v1/auth/staff', {
      'pin': pin,
      'name': name,
      'access': access.name,
    });

    return StaffOutcome(
      PinResult.values.byName(body['result']! as String),
      decodeActor(body['actor']),
    );
  }

  @override
  Future<void> signOut() async {
    await _client.post('/v1/auth/sign-out', {});
  }

  @override
  Future<Actor> preview(Role role) async {
    final body = await _client.post('/v1/auth/preview', {
      'role': role.name,
    });
    final actor = decodeActor(body['actor']);

    if (actor == null) {
      throw StateError('preview returned no actor');
    }

    return actor;
  }

  Future<AuthOutcome> _authPost(String path, Json payload) async {
    final body = await _client.post(path, payload);

    return AuthOutcome(
      SignInResult.values.byName(body['result']! as String),
      decodeActor(body['actor']),
    );
  }
}
