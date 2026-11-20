import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket/app.dart';
import 'package:pocket/care/compose.dart';
import 'package:pocket/domain/auth.dart';
import 'package:pocket/session/pocket_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phone-width surface matching the web column (~430 logical px).
const _phone = Size(1290, 2796); // 430×932 @3x

Finder _bar(String label) {
  return find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
}

Future<void> _launch(WidgetTester tester) async {
  tester.view.physicalSize = _phone;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final prefs = await SharedPreferences.getInstance();
  final scope = PocketScope(composeDesk(prefs));
  await scope.load();

  await tester.pumpWidget(PocketApp(scope: scope));
  await tester.pumpAndSettle();
}

Future<void> _owner(WidgetTester tester) async {
  await tester.tap(find.text('I’m Pamela’s main carer'));
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining('Continue as'));
  await tester.pumpAndSettle();
}

Future<void> _family(WidgetTester tester) async {
  await tester.tap(find.text('I’m family'));
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining('Continue as'));
  await tester.pumpAndSettle();
}

Future<void> _pin(WidgetTester tester, String name, String pin) async {
  await tester.tap(find.text('I’m a support worker'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ChoiceChip, name));
  await tester.pumpAndSettle();

  for (final digit in pin.split('')) {
    await tester.tap(find.widgetWithText(OutlinedButton, digit));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> _signOut(WidgetTester tester) async {
  await tester.tap(_bar('More'));
  await tester.pumpAndSettle();
  final out = find.text('Sign out');
  await tester.ensureVisible(out);
  await tester.pumpAndSettle();
  await tester.tap(out);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // 1. Alex: handover → add update → new handover → More QR
  testWidgets('walk 1 Alex handover update More QR', (tester) async {
    await _launch(tester);
    await _owner(tester);

    expect(find.text('Handover'), findsOneWidget);
    expect(find.textContaining('porridge'), findsWidgets);

    await tester.tap(find.text('Add update'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Note'),
      'Walk note after tea.',
    );
    await tester.pump();
    final save = find.text('Save');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.textContaining('Walk note after tea.'), findsWidgets);

    await tester.tap(_bar('More'));
    await tester.pumpAndSettle();
    expect(find.text('Staff PIN'), findsOneWidget);
  });

  // 2. Chris accepts a request
  testWidgets('walk 2 Chris accepts a request', (tester) async {
    await _launch(tester);
    await _family(tester);
    await tester.tap(_bar('Family'));
    await tester.pumpAndSettle();

    // Phone column keeps requests below the fold; ListView builds lazily.
    final ask = find.text('Can someone take Mum to her appointment?');
    await tester.dragUntilVisible(
      ask,
      find.byType(ListView).first,
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();
    expect(ask, findsOneWidget);
    await tester.tap(find.text('I can help').first);
    await tester.pumpAndSettle();

    expect(find.text('Chris can help'), findsWidgets);
  });

  // 3. Jordan: PIN, no Family/Guide, More is sign out only
  testWidgets('walk 3 Jordan staff limits', (tester) async {
    await _launch(tester);
    await _pin(tester, 'Jordan', demoPin);

    expect(_bar('Today'), findsOneWidget);
    expect(_bar('Family'), findsNothing);

    await tester.tap(_bar('Chat'));
    await tester.pumpAndSettle();
    expect(find.text('Guide'), findsNothing);

    await tester.tap(_bar('More'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Reports'), findsNothing);
    expect(find.text('Add a report'), findsNothing);
    expect(find.text('Staff PIN'), findsNothing);
  });

  // 4. Alex revokes → Jordan rejected → Alex restores
  testWidgets('walk 4 revoke reject restore', (tester) async {
    await _launch(tester);
    await _owner(tester);
    await tester.tap(_bar('More'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Turn off access'));
    await tester.tap(find.text('Turn off access'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Turn off'));
    await tester.pumpAndSettle();

    await _signOut(tester);
    await _pin(tester, 'Jordan', demoPin);
    expect(find.text('This code has been turned off.'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await _owner(tester);
    await tester.tap(_bar('More'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Turn access back on'));
    await tester.tap(find.text('Turn access back on'));
    await tester.pumpAndSettle();

    await _signOut(tester);
    await _pin(tester, 'Jordan', demoPin);
    expect(_bar('Today'), findsOneWidget);
  });
}
