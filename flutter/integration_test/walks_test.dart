import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pocket/domain/auth.dart';
import 'package:pocket/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

const _note = 'Walk note after tea.';
const _pause = Duration(seconds: 2);

Finder _bar(String label) {
  return find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
}

// Scrolls a control into view, then taps it. Lists below the fold are built lazily.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  if (finder.hitTestable().evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 400);
  }

  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _pauseOn(WidgetTester tester) async {
  await tester.pump(_pause);
}

Future<void> _signOut(WidgetTester tester) async {
  await _tap(tester, _bar('More'));
  await _tap(tester, find.text('Sign out'));
  expect(find.text('I’m Pamela’s main carer'), findsOneWidget);
}

// Alex reads the handover, writes one note, and reveals the staff PIN.
Future<void> _alex(WidgetTester tester) async {
  await _tap(tester, find.text('I’m Pamela’s main carer'));
  await _tap(tester, find.textContaining('Continue as'));
  expect(find.textContaining('porridge'), findsWidgets);
  await _pauseOn(tester);

  await _tap(tester, find.text('Add update'));
  await tester.enterText(find.widgetWithText(TextField, 'Note'), _note);
  await tester.pump();
  await _tap(tester, find.text('Save'));
  expect(find.textContaining(_note), findsWidgets);
  await _pauseOn(tester);

  await _tap(tester, _bar('More'));
  expect(find.text('Staff PIN'), findsOneWidget);
  final dots = find.text('••••');
  await tester.ensureVisible(dots);
  final hold = await tester.startGesture(tester.getCenter(dots));
  await tester.pump(const Duration(milliseconds: 600));
  expect(find.text(demoPin), findsOneWidget);
  await _pauseOn(tester);
  await hold.up();
  await tester.pumpAndSettle();

  await _signOut(tester);
}

// Chris accepts the open appointment request.
Future<void> _chris(WidgetTester tester) async {
  await _tap(tester, find.text('I’m family'));
  await _tap(tester, find.textContaining('Continue as'));
  await _tap(tester, _bar('Family'));
  final help = find.text('I can help');
  await tester.scrollUntilVisible(help, 400);
  await tester.pumpAndSettle();
  await tester.tap(help.hitTestable().first);
  await tester.pumpAndSettle();
  expect(find.text('Chris can help'), findsWidgets);
  await _pauseOn(tester);
  await _signOut(tester);
}

// Jordan enters the PIN. Family and the guide stay closed.
Future<void> _jordan(WidgetTester tester) async {
  await _tap(tester, find.text('I’m a support worker'));
  await _tap(tester, find.widgetWithText(ChoiceChip, 'Jordan'));

  for (final digit in demoPin.split('')) {
    await tester.tap(find.widgetWithText(OutlinedButton, digit));
    await tester.pump();
  }

  await tester.pumpAndSettle();
  expect(_bar('Today'), findsOneWidget);
  expect(_bar('Family'), findsNothing);
  await _pauseOn(tester);

  await _tap(tester, _bar('Chat'));
  expect(find.text('Pocket Guide'), findsNothing);

  await _tap(tester, _bar('More'));
  expect(find.text('Sign out'), findsOneWidget);
  expect(find.text('Staff PIN'), findsNothing);
  expect(find.text('Reports'), findsNothing);
  await _pauseOn(tester);
}

// The three presentation walks, on the phone, from a fresh sample household.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('three presentation walks', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    await app.main();
    await tester.pumpAndSettle();

    await _alex(tester);
    await _chris(tester);
    await _jordan(tester);
  });
}
