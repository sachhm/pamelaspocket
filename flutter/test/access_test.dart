import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket/adapters/local/local_auth.dart';
import 'package:pocket/adapters/local/local_files.dart';
import 'package:pocket/adapters/local/local_model.dart';
import 'package:pocket/adapters/local/local_notify.dart';
import 'package:pocket/adapters/local/local_records.dart';
import 'package:pocket/adapters/local/local_scan.dart';
import 'package:pocket/app.dart';
import 'package:pocket/care/desk.dart';
import 'package:pocket/domain/auth.dart';
import 'package:pocket/domain/commands.dart';
import 'package:pocket/domain/enums.dart';
import 'package:pocket/session/pocket_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<CareDesk> _desk() async {
  final prefs = await SharedPreferences.getInstance();

  return CareDesk(
    LocalAuth(prefs),
    LocalRecords(prefs),
    const LocalModel(),
    LocalFiles(PrefsShelf(prefs)),
    notify: LocalNotify(),
    scan: const LocalScan(),
  );
}

Future<void> _launch(WidgetTester tester, {CareDesk? desk}) async {
  tester.view.physicalSize = const Size(1170, 9000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final built = desk ?? await _desk();
  final scope = PocketScope(built);
  await scope.load();

  await tester.pumpWidget(PocketApp(scope: scope));
  await tester.pumpAndSettle();
}

Future<void> _ownerDemo(WidgetTester tester) async {
  await tester.tap(find.text('I’m Pamela’s main carer'));
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining('Continue as'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Later finishes onboarding; next sign-in opens Today', (
    tester,
  ) async {
    final desk = await _desk();
    await desk.load();
    await desk.signIn(Role.owner, ownerEmail, demoPassword);
    final records = LocalRecords(await SharedPreferences.getInstance());
    await records.commit(const OnboardingSet(Onboarding.pending));
    await desk.signOut();

    await _launch(tester, desk: await _desk());
    await _ownerDemo(tester);

    expect(find.text('Later'), findsOneWidget);
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();

    expect(find.text('Later'), findsNothing);
    expect(find.textContaining('porridge'), findsWidgets);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sign out'));
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    await _ownerDemo(tester);

    expect(find.text('Later'), findsNothing);
    expect(find.textContaining('porridge'), findsWidgets);
  });

  testWidgets('revoke confirm then Jordan sees turned-off; restore works', (
    tester,
  ) async {
    await _launch(tester);
    await _ownerDemo(tester);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Turn off access'));
    await tester.tap(find.text('Turn off access'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Turn off'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Sign out'));
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('I’m a support worker'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Jordan'));
    await tester.pumpAndSettle();
    for (final d in demoPin.split('')) {
      await tester.tap(find.widgetWithText(OutlinedButton, d));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('This code has been turned off.'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('I’m Pamela’s main carer'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Continue as'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Turn access back on'));
    await tester.tap(find.text('Turn access back on'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Sign out'));
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('I’m a support worker'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Jordan'));
    await tester.pumpAndSettle();
    for (final d in demoPin.split('')) {
      await tester.tap(find.widgetWithText(OutlinedButton, d));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.textContaining('porridge'), findsWidgets);
  });

  testWidgets('Chris off rejects with the same copy as a bad password', (
    tester,
  ) async {
    await _launch(tester);
    await _ownerDemo(tester);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    final chris = find.widgetWithText(SwitchListTile, 'Chris');
    await tester.ensureVisible(chris);
    await tester.tap(chris);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Turn off'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Sign out'));
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('I’m family'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Continue as'));
    await tester.pumpAndSettle();

    expect(
      find.text('That email or password was not accepted.'),
      findsOneWidget,
    );
  });

  testWidgets('owner More shows the staff PIN', (tester) async {
    await _launch(tester);
    await _ownerDemo(tester);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('Staff PIN'), findsOneWidget);
  });

  testWidgets('View as is debug-only', (tester) async {
    await _launch(tester);
    await _ownerDemo(tester);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('View as'), kDebugMode ? findsOneWidget : findsNothing);
  });
}
