import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pocket/domain/chat.dart';
import 'package:pocket/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

const _hold = Duration(seconds: 5);
const _breakfast = 'What does she usually have for breakfast?';
const _dose = 'What is her dose?';

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  debugPrint('SHOT:$name');
  await Future<void>.delayed(_hold);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    final scrolls = find.byType(Scrollable);

    if (scrolls.evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(finder, 100, scrollable: scrolls.first);
    }
  }

  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _ask(WidgetTester tester, String text) async {
  final field = find.byType(TextField);

  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, text);
  await tester.pumpAndSettle();

  final send = find.widgetWithText(FilledButton, 'Send');

  expect(tester.widget<FilledButton>(send).onPressed, isNotNull);
  await tester.tap(send);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('chat and guide path on a phone', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    await app.main();
    await tester.pumpAndSettle();
    await _tap(tester, find.text('I’m a support worker'));
    await _tap(tester, find.widgetWithText(ChoiceChip, 'Jordan'));
    for (final digit in ['2', '5', '8', '0']) {
      await _tap(tester, find.widgetWithText(OutlinedButton, digit));
    }
    await _tap(tester, find.text('Chat'));

    await _ask(tester, _breakfast);
    expect(find.textContaining('porridge'), findsOneWidget);
    expect(find.text('AI reply'), findsWidgets);
    await _shot(tester, 'chat_breakfast');

    await _ask(tester, _dose);
    expect(
      find.text("I don't have that in Pamela's notes.", skipOffstage: false),
      findsOneWidget,
    );
    // The new reply sits under the fold after the seeded thread.
    await tester.drag(find.byType(ListView).first, const Offset(0, -800));
    await tester.pumpAndSettle();
    await _shot(tester, 'chat_unknown');
    await _tap(tester, find.text('Ask Alex or Chris'));
    await tester.tap(find.widgetWithText(ListTile, 'Chris'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(
      find.text('Sent to Chris', skipOffstage: false),
      findsOneWidget,
    );
    await _shot(tester, 'chat_sent');
  });

  testWidgets('guide draft reaches the diary only after confirm', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    await app.main();
    await tester.pumpAndSettle();
    await _tap(tester, find.text('I’m Pamela’s main carer'));
    await _tap(tester, find.textContaining('Continue as'));
    await _tap(tester, find.text('Chat'));
    await _tap(tester, find.text('Pocket Guide'));
    await _shot(tester, 'guide');

    await _tap(tester, find.text(guideHandover));
    expect(find.text('Add to the diary'), findsOneWidget);
    expect(find.text(handoverDraft), findsOneWidget);
    await _shot(tester, 'guide_draft');

    await _tap(tester, find.text('Add to the diary'));
    expect(find.text('Add this to the diary?'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Add to the diary'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Today'));
    await _tap(tester, find.text(handoverDraft));
    await _shot(tester, 'today_draft');
  });
}
