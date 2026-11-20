import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pocket/main.dart' as app;

const _hold = Duration(seconds: 8);

Finder _bar(String label) {
  return find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
}

// Starts from the saved Alex session, turns the PIN off from the debug
// button, and checks Jordan gets the turned-off sentence. Restores at the end.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('debug toggle turns the PIN off for staff', (tester) async {
    await app.main();
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('Signed in as Alex, main carer'),
      findsOneWidget,
    );

    await tester.tap(_bar('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Debug: turn the PIN off'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('I’m a support worker'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Jordan'));
    await tester.pumpAndSettle();
    for (final digit in ['2', '5', '8', '0']) {
      await tester.tap(find.widgetWithText(OutlinedButton, digit));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('This code has been turned off.'), findsOneWidget);

    // Held on screen so the simulator can be captured.
    debugPrint('REVOKED_SHOWN');
    await Future<void>.delayed(_hold);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('I’m Pamela’s main carer'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Continue as'));
    await tester.pumpAndSettle();
    await tester.tap(_bar('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Debug: turn the PIN on'));
    await tester.pumpAndSettle();

    expect(find.text('Debug: turn the PIN off'), findsOneWidget);
  });
}
