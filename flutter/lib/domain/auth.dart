import 'enums.dart';
import 'records.dart';

// Demo household secrets from 00-product.
const ownerEmail = 'alex@pocket.demo';
const familyEmail = 'chris@pocket.demo';
const demoPassword = 'pocket';
const demoPin = '2580';
const pinLength = 4;
const staffNames = ['Jordan', 'Sam'];

String emailFor(Role role) {
  if (role == Role.family) {
    return familyEmail;
  }

  return ownerEmail;
}

Actor actorFor(Role role) {
  return switch (role) {
    Role.owner => const Actor(role: Role.owner, name: 'Alex'),
    Role.family => const Actor(role: Role.family, name: 'Chris'),
    Role.staff => const Actor(role: Role.staff, name: 'Jordan'),
  };
}

/// Staff have no email account, so an email sign-in as staff always fails.
SignInResult checkSignIn(Role role, String email, String password) {
  if (role == Role.staff) {
    return SignInResult.rejected;
  }

  final emailOk = email.trim().toLowerCase() == emailFor(role);

  if (emailOk && password == demoPassword) {
    return SignInResult.ok;
  }

  return SignInResult.rejected;
}

/// Revoked wins over a correct PIN: the code is off for everyone.
PinResult checkPin(String pin, AccessState access) {
  if (access == AccessState.revoked) {
    return PinResult.revoked;
  }

  if (pin == demoPin) {
    return PinResult.ok;
  }

  return PinResult.wrong;
}
