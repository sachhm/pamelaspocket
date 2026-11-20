import 'package:flutter_test/flutter_test.dart';
import 'package:pocket/domain/auth.dart';
import 'package:pocket/domain/enums.dart';

void main() {
  group('checkSignIn', () {
    test('wrong password rejects', () {
      final result = checkSignIn(Role.owner, ownerEmail, 'nope');

      expect(result, SignInResult.rejected);
    });

    test('demo password accepts owner and family', () {
      expect(
        checkSignIn(Role.owner, ownerEmail, demoPassword),
        SignInResult.ok,
      );
      expect(
        checkSignIn(Role.family, familyEmail, demoPassword),
        SignInResult.ok,
      );
    });

    test('email is trimmed and case-insensitive', () {
      final result = checkSignIn(
        Role.owner,
        '  Alex@Pocket.Demo ',
        demoPassword,
      );

      expect(result, SignInResult.ok);
    });

    test('family email does not open the owner account', () {
      final result = checkSignIn(Role.owner, familyEmail, demoPassword);

      expect(result, SignInResult.rejected);
    });

    test('staff email sign-in rejects', () {
      expect(
        checkSignIn(Role.staff, ownerEmail, demoPassword),
        SignInResult.rejected,
      );
      expect(
        checkSignIn(Role.staff, 'jordan@pocket.demo', demoPassword),
        SignInResult.rejected,
      );
    });
  });

  group('checkPin', () {
    test('2580 accepts', () {
      expect(checkPin('2580', AccessState.active), PinResult.ok);
    });

    test('any other four digits are wrong', () {
      for (final pin in ['0000', '2581', '0852', '9999']) {
        expect(checkPin(pin, AccessState.active), PinResult.wrong);
      }
    });

    test('revoked access is revoked, even with the right PIN', () {
      expect(checkPin('2580', AccessState.revoked), PinResult.revoked);
      expect(checkPin('1111', AccessState.revoked), PinResult.revoked);
    });
  });

  test('demo actors', () {
    expect(actorFor(Role.owner).name, 'Alex');
    expect(actorFor(Role.family).name, 'Chris');
    expect(actorFor(Role.staff).name, 'Jordan');
  });
}
