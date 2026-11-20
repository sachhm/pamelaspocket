import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket/app.dart';
import 'package:pocket/care/compose.dart';
import 'package:pocket/session/pocket_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _openPin(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final prefs = await SharedPreferences.getInstance();
  final scope = PocketScope(composeDesk(prefs));
  await scope.load();

  await tester.pumpWidget(PocketApp(scope: scope));
  await tester.pumpAndSettle();
  await tester.tap(find.text('I’m a support worker'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ChoiceChip, 'Jordan'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(OutlinedButton, '2'));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a digit fills one dot and leaves the others waiting', (
    tester,
  ) async {
    await _openPin(tester);
    await tester.pumpAndSettle();

    final scales = tester
        .widgetList<AnimatedScale>(find.byType(AnimatedScale))
        .map((dot) => dot.scale);

    expect(scales.where((scale) => scale == 1).length, 1);
    expect(scales.where((scale) => scale < 1).length, 3);
  });

  testWidgets('reduced motion holds every dot at full size', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );

    await _openPin(tester);

    final dots = tester.widgetList<AnimatedScale>(find.byType(AnimatedScale));

    expect(dots.map((dot) => dot.scale), everyElement(1));
    expect(dots.map((dot) => dot.duration), everyElement(Duration.zero));
  });
}
