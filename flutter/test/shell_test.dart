import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket/app.dart';
import 'package:pocket/care/compose.dart';
import 'package:pocket/domain/time.dart';
import 'package:pocket/session/pocket_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tabs = ['Today', 'About', 'Chat', 'Family', 'More'];

Finder _barLabel(String label) {
  return find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
}

// iOS accessibility XXXL body is 53 pt against 17 pt.
const _largestText = 3.12;

// Counts the laid-out lines of a Text by its distinct selection-box rows.
int _lines(WidgetTester tester, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: text.length),
  );

  return boxes.map((box) => box.top).toSet().length;
}

Finder _key(String label) {
  return find.widgetWithText(OutlinedButton, label);
}

// Opens the app over whatever the mock device storage holds.
Future<void> _launch(WidgetTester tester) async {
  // Phone-tall surface so More / PIN controls stay hittable.
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final prefs = await SharedPreferences.getInstance();
  final scope = PocketScope(composeDesk(prefs));
  await scope.load();

  await tester.pumpWidget(PocketApp(scope: scope));
  await tester.pumpAndSettle();
}

Future<void> _ownerDemo(WidgetTester tester) async {
  await _launch(tester);
  await tester.tap(find.text('I’m Pamela’s main carer'));
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining('Continue as'));
  await tester.pumpAndSettle();
}

Future<void> _pin(WidgetTester tester, String name, String pin) async {
  await tester.ensureVisible(find.text('I’m a support worker'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('I’m a support worker'));
  await tester.pumpAndSettle();
  final chip = find.widgetWithText(ChoiceChip, name, skipOffstage: false);
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();

  for (final digit in pin.split('')) {
    await tester.tap(_key(digit));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> _signOut(WidgetTester tester) async {
  await tester.tap(_barLabel('More'));
  await tester.pumpAndSettle();
  final signOut = find.text('Sign out');
  await tester.ensureVisible(signOut);
  await tester.pumpAndSettle();
  await tester.tap(signOut);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('opens on Welcome with three paths', (tester) async {
    await _launch(tester);

    expect(find.text('Pamela'), findsOneWidget);
    expect(find.text('I’m Pamela’s main carer'), findsOneWidget);
    expect(find.text('I’m family'), findsOneWidget);
    expect(find.text('I’m a support worker'), findsOneWidget);
    expect(
      find.text('The main carer gives you a four-digit code.'),
      findsOneWidget,
    );
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('demo account lands the owner on Today with five tabs', (
    tester,
  ) async {
    await _ownerDemo(tester);

    for (final label in _tabs) {
      expect(_barLabel(label), findsOneWidget);
    }
    expect(find.text('Add update'), findsOneWidget);
  });

  testWidgets('wrong password shows the rejection under the button', (
    tester,
  ) async {
    await _launch(tester);
    await tester.tap(find.text('I’m family'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'chris@pocket.demo',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'wrong');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(
      find.text('That email or password was not accepted.'),
      findsOneWidget,
    );
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('family signs in with typed credentials', (tester) async {
    await _launch(tester);
    await tester.tap(find.text('I’m family'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'chris@pocket.demo',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'pocket',
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Signed in as Chris, family'), findsOneWidget);
  });

  testWidgets('name chip shows the signed-in first name on every tab', (
    tester,
  ) async {
    await _ownerDemo(tester);

    for (final label in _tabs) {
      await tester.tap(_barLabel(label));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Signed in as Alex, main carer'),
        findsOneWidget,
      );
    }
  });

  testWidgets('PIN pad is disabled until a staff name is picked', (
    tester,
  ) async {
    await _launch(tester);
    await tester.tap(find.text('I’m a support worker'));
    await tester.pumpAndSettle();

    expect(tester.widget<OutlinedButton>(_key('2')).onPressed, isNull);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Sam'));
    await tester.pumpAndSettle();

    expect(tester.widget<OutlinedButton>(_key('2')).onPressed, isNotNull);
  });

  testWidgets('PIN dots announce progress', (tester) async {
    await _launch(tester);
    await tester.tap(find.text('I’m a support worker'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Jordan'));
    await tester.pumpAndSettle();

    await tester.tap(_key('2'));
    await tester.tap(_key('5'));
    await tester.pump();

    expect(find.bySemanticsLabel('2 of 4 digits entered'), findsOneWidget);
  });

  testWidgets('fourth digit submits; staff bar hides Family', (tester) async {
    await _launch(tester);
    await _pin(tester, 'Sam', '2580');

    expect(_barLabel('Today'), findsOneWidget);
    expect(_barLabel('Family'), findsNothing);
    expect(
      find.bySemanticsLabel('Signed in as Sam, support worker'),
      findsOneWidget,
    );
  });

  testWidgets('wrong PIN shows the error and clears the dots', (tester) async {
    await _launch(tester);
    await _pin(tester, 'Jordan', '1234');

    expect(find.text('That PIN is not right.'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(_key('2'));
    await tester.pump();

    expect(find.text('That PIN is not right.'), findsNothing);
    expect(find.bySemanticsLabel('1 of 4 digits entered'), findsOneWidget);
  });

  testWidgets('owner revoke asks then turns the PIN off', (tester) async {
    await _ownerDemo(tester);
    await tester.tap(_barLabel('More'));
    await tester.pumpAndSettle();

    final turnOff = find.text('Turn off access');
    await tester.ensureVisible(turnOff);
    await tester.pumpAndSettle();
    await tester.tap(turnOff);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Turn the PIN off?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Turn off'));
    await tester.pumpAndSettle();

    final signOut = find.text('Sign out');
    await tester.ensureVisible(signOut);
    await tester.pumpAndSettle();
    await tester.tap(signOut);
    await tester.pumpAndSettle();

    await _pin(tester, 'Jordan', '2580');

    expect(find.text('This code has been turned off.'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('sign-out returns to Welcome', (tester) async {
    await _ownerDemo(tester);
    await _signOut(tester);

    expect(find.text('I’m Pamela’s main carer'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('relaunch keeps Alex on Today', (tester) async {
    await _ownerDemo(tester);

    await tester.pumpWidget(const SizedBox());
    await _launch(tester);

    expect(find.text('Add update'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Signed in as Alex, main carer'),
      findsOneWidget,
    );
  });

  testWidgets('Add update shows on Today only', (tester) async {
    await _ownerDemo(tester);

    await tester.tap(_barLabel('Chat'));
    await tester.pumpAndSettle();

    expect(find.text('Add update'), findsNothing);
  });

  testWidgets('Add update sits below Today, not over it', (tester) async {
    await _ownerDemo(tester);

    final list = tester.getRect(find.byType(ListView).first);
    final label = tester.getRect(find.text('Add update'));

    expect(label.top, greaterThanOrEqualTo(list.bottom));
  });

  testWidgets('Continue the story sits below About', (tester) async {
    await _ownerDemo(tester);

    await tester.tap(_barLabel('About'));
    await tester.pumpAndSettle();

    final list = tester.getRect(find.byType(ListView).last);
    final label = tester.getRect(find.text('Continue the story'));

    expect(label.top, greaterThanOrEqualTo(list.bottom));
    expect(find.text('Add update'), findsNothing);
  });

  testWidgets('system Back on another tab returns to Today', (tester) async {
    await _ownerDemo(tester);

    await tester.tap(_barLabel('Chat'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Add update'), findsOneWidget);
  });

  testWidgets('errors are announced where the platform supports it', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(supportsAnnounce: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await _launch(tester);
    await _pin(tester, 'Jordan', '1234');

    expect(
      tester.takeAnnouncements(),
      contains(isAccessibilityAnnouncement('That PIN is not right.')),
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('I’m family'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'x');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(
      tester.takeAnnouncements(),
      contains(
        isAccessibilityAnnouncement('That email or password was not accepted.'),
      ),
    );
  });

  testWidgets('Continue dismisses the keyboard so the error shows', (
    tester,
  ) async {
    await _launch(tester);
    await tester.tap(find.text('I’m family'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'x');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('demo sign-in does not offer to save the demo password', (
    tester,
  ) async {
    await _ownerDemo(tester);

    final finishes = tester.testTextInput.log.where(
      (call) => call.method == 'TextInput.finishAutofillContext',
    );
    expect(finishes.map((call) => call.arguments), everyElement(isFalse));
  });

  testWidgets('hardware digits work on the PIN pad', (tester) async {
    await _launch(tester);
    await tester.tap(find.text('I’m a support worker'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Jordan'));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyEvent(LogicalKeyboardKey.numpad5, character: '5');
    await tester.sendKeyEvent(LogicalKeyboardKey.digit8);
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();

    expect(find.bySemanticsLabel('2 of 4 digits entered'), findsOneWidget);
  });

  testWidgets('largest iOS text keeps Pamela and Delete on one line', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = _largestText;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _launch(tester);
    expect(_lines(tester, 'Pamela'), 1);

    await tester.ensureVisible(find.text('I’m a support worker'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I’m a support worker'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(_lines(tester, 'Delete'), 1);
  });

  testWidgets('Pamela’s name and date follow the text size', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _ownerDemo(tester);

    final date = find.text(formatDay(DateTime.now()));
    final style = tester.widget<Text>(date).style!;
    final scaled = MediaQuery.textScalerOf(tester.element(date));

    expect(scaled.scale(style.fontSize!), style.fontSize! * 2);
    expect(find.text('Pamela'), findsOneWidget);
  });

  testWidgets('her name takes the bar once Today scrolls', (tester) async {
    await _ownerDemo(tester);

    final inBar = find.descendant(
      of: find.byType(AppBar),
      matching: find.text('Pamela'),
    );
    expect(inBar, findsNothing);

    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(inBar, findsOneWidget);
  });

  testWidgets('error icon grows with the text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _launch(tester);
    await _pin(tester, 'Jordan', '1234');

    expect(tester.getSize(find.byIcon(Icons.error_outline)).height, 48);
  });

  testWidgets('More actions line up with the name', (tester) async {
    await _ownerDemo(tester);
    await tester.tap(_barLabel('More'));
    await tester.pumpAndSettle();

    final name = tester
        .getTopLeft(
          find.descendant(
            of: find.byType(SingleChildScrollView),
            matching: find.text('Alex'),
          ),
        )
        .dx;

    expect(tester.getTopLeft(find.text('Sign out')).dx, name);

    final viewAs = find.text('View as');
    await tester.ensureVisible(viewAs);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(viewAs).dx, name);
  });

  testWidgets('text scale 2.0 fits a phone without overflow', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _launch(tester);
    await tester.ensureVisible(find.text('I’m a support worker'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I’m a support worker'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('I’m Pamela’s main carer'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Continue as'));
    await tester.pumpAndSettle();

    for (final label in ['About', 'Chat', 'Family', 'More']) {
      await tester.tap(_barLabel(label));
      await tester.pumpAndSettle();
    }
  });
}
