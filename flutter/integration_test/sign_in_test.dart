import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pocket/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

// Real device storage: leaves Alex signed in so a relaunch can be checked.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('owner signs in with the demo account', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    await app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.text('I’m Pamela’s main carer'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Continue as'));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('Signed in as Alex, main carer'),
      findsOneWidget,
    );
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
