import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/auth.dart';
import '../../domain/codec.dart';
import '../../domain/enums.dart';
import '../../domain/records.dart';
import '../../ports/auth_port.dart';

const actorKey = 'pamelas-pocket.actor.v2';

/// Demo accounts checked on device. The signed-in actor is the only thing
/// stored here; sign-out removes it and leaves the records alone.
class LocalAuth implements AuthPort {
  LocalAuth(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<Actor?> current() async {
    final raw = _prefs.getString(actorKey);

    if (raw == null) {
      return null;
    }

    try {
      return decodeActor(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  @override
  Future<AuthOutcome> signIn(Role role, String email, String password) async {
    final result = checkSignIn(role, email, password);

    if (result != SignInResult.ok) {
      return AuthOutcome(result, null);
    }

    return AuthOutcome(result, await _save(actorFor(role)));
  }

  // No second household locally: sign-up is sign-in with the demo accounts.
  @override
  Future<AuthOutcome> signUp(Role role, String email, String password) {
    return signIn(role, email, password);
  }

  @override
  Future<StaffOutcome> enterStaff(
    String pin,
    AccessState access,
    String name,
  ) async {
    final result = checkPin(pin, access);

    if (result != PinResult.ok) {
      return StaffOutcome(result, null);
    }

    return StaffOutcome(
      result,
      await _save(Actor(role: Role.staff, name: name)),
    );
  }

  @override
  Future<void> signOut() async {
    await _prefs.remove(actorKey);
  }

  @override
  Future<Actor> preview(Role role) {
    return _save(actorFor(role));
  }

  Future<Actor> _save(Actor actor) async {
    await _prefs.setString(actorKey, jsonEncode(encodeActor(actor)));

    return actor;
  }
}
