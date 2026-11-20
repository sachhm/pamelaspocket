import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket/ui/paper_motion.dart';

Future<void> _host(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

double _dy(WidgetTester tester) {
  return tester
      .widget<Transform>(
        find.descendant(
          of: find.byType(PaperSlip),
          matching: find.byType(Transform),
        ),
      )
      .transform
      .getTranslation()
      .y;
}

void main() {
  testWidgets('rewritten ink keeps both lines during the fade', (tester) async {
    final text = ValueNotifier('From Alex');

    await _host(
      tester,
      ValueListenableBuilder<String>(
        valueListenable: text,
        builder: (context, value, _) {
          return InkSwap(token: value, child: Text(value));
        },
      ),
    );

    text.value = 'Updating…';
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text('From Alex'), findsOneWidget);
    expect(find.text('Updating…'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('From Alex'), findsNothing);
    expect(find.text('Updating…'), findsOneWidget);
  });

  testWidgets('a slip drops onto its line', (tester) async {
    await _host(
      tester,
      const PaperSlip(phase: SlipPhase.settling, child: Text('She had tea.')),
    );

    expect(_dy(tester), lessThan(0));

    await tester.pump(const Duration(milliseconds: 80));
    expect(_dy(tester), lessThan(0));
    expect(_dy(tester), greaterThan(-8));

    await tester.pumpAndSettle();
    expect(_dy(tester), 0);
  });

  testWidgets('reduced motion fades a slip without travel', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await _host(
      tester,
      const PaperSlip(phase: SlipPhase.settling, child: Text('She had tea.')),
    );
    await tester.pump(const Duration(milliseconds: 40));

    // The platform shortens the fade. The slip still must not travel.
    expect(_dy(tester), 0);
    expect(find.text('She had tea.'), findsOneWidget);
  });

  testWidgets('a thread settles only the note that just arrived', (
    tester,
  ) async {
    final ids = ValueNotifier<List<String>>(['a']);

    await _host(
      tester,
      ValueListenableBuilder<List<String>>(
        valueListenable: ids,
        builder: (context, value, _) {
          return FreshSlips(ids: value, item: (id) => Text(id));
        },
      ),
    );

    expect(find.byType(PaperSlip), findsNothing);

    ids.value = ['a', 'b'];
    await tester.pump();

    expect(find.byType(PaperSlip), findsOneWidget);
    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(_dy(tester), lessThan(0));
  });
}
