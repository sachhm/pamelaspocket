import '../domain/enums.dart';
import '../domain/records.dart';

class AuthOutcome {
  const AuthOutcome(this.result, this.actor);

  final SignInResult result;
  final Actor? actor;
}

class StaffOutcome {
  const StaffOutcome(this.result, this.actor);

  final PinResult result;
  final Actor? actor;
}

/// Accounts and the staff gate. A remote adapter replaces the local one
/// without touching the desk or the screens.
abstract interface class AuthPort {
  Future<Actor?> current();

  Future<AuthOutcome> signIn(Role role, String email, String password);

  /// Plug for a real account later. Local accepts only the demo accounts.
  Future<AuthOutcome> signUp(Role role, String email, String password);

  Future<StaffOutcome> enterStaff(String pin, AccessState access, String name);

  Future<void> signOut();

  /// Debug only: switch actor without a password.
  Future<Actor> preview(Role role);
}
