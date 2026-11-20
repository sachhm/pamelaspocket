import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket/adapters/local/local_auth.dart';
import 'package:pocket/adapters/local/local_files.dart';
import 'package:pocket/adapters/local/local_model.dart';
import 'package:pocket/adapters/local/local_notify.dart';
import 'package:pocket/adapters/local/local_records.dart';
import 'package:pocket/app.dart';
import 'package:pocket/care/desk.dart';
import 'package:pocket/domain/commands.dart';
import 'package:pocket/domain/records.dart';
import 'package:pocket/features/family/family_screen.dart';
import 'package:pocket/ports/record_port.dart';
import 'package:pocket/session/pocket_scope.dart';
import 'package:pocket/ui/announced.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _launch(WidgetTester tester, {RecordPort? records}) async {
  tester.view.physicalSize = const Size(1170, 9000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final prefs = await SharedPreferences.getInstance();
  final desk = CareDesk(
    LocalAuth(prefs),
    records ?? LocalRecords(prefs),
    const LocalModel(),
    LocalFiles(PrefsShelf(prefs)),
    notify: LocalNotify(),
  );
  final scope = PocketScope(desk);
  await scope.load();

  await tester.pumpWidget(PocketApp(scope: scope));
  await tester.pumpAndSettle();
}

Future<void> _owner(WidgetTester tester) async {
  await _launch(tester);
  await tester.tap(find.text('I’m Pamela’s main carer'));
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining('Continue as'));
  await tester.pumpAndSettle();
}

Future<void> _family(WidgetTester tester) async {
  await _launch(tester);
  await tester.tap(find.text('I’m family'));
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining('Continue as'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Chris accepts the appointment request', (tester) async {
    await _family(tester);
    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();

    expect(
      find.text('Can someone take Mum to her appointment?'),
      findsOneWidget,
    );
    await tester.tap(find.text('I can help').first);
    await tester.pumpAndSettle();

    // Seed already has Chris on the haircut trip and the prescription.
    expect(find.text('Chris can help'), findsWidgets);
    expect(
      find.text('Can someone take Mum to her appointment?'),
      findsOneWidget,
    );
    expect(find.text('I can help'), findsOneWidget);
  });

  testWidgets('Ask the family names the GP place and time', (tester) async {
    await _owner(tester);
    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Routine check'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ask the family to help'));
    await tester.pumpAndSettle();

    // Leaf must show the ask landed; do not leave Ask tappable.
    expect(find.text('Ask the family to help'), findsNothing);
    expect(find.textContaining('Asked the family'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.textContaining('Hills Medical'), findsWidgets);
    expect(find.textContaining('10:30 am'), findsWidgets);
    expect(
      find.textContaining('Can someone take Mum to Hills Medical'),
      findsOneWidget,
    );
  });

  // Destructive remove needs a confirm, same as diary entries.
  testWidgets('Remove a request asks before deleting', (tester) async {
    await _owner(tester);
    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();

    const open = 'Who can visit this weekend?';
    expect(find.text(open), findsOneWidget);
    await tester.tap(find.text('Remove').at(1));
    await tester.pumpAndSettle();

    expect(find.text('Remove this request?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text(open), findsOneWidget);

    await tester.tap(find.text('Remove').at(1));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Remove'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(open), findsNothing);
  });

  testWidgets('Alex adds a GP visit on Today and Family', (tester) async {
    await _owner(tester);
    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add an appointment'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Place'),
      'GP clinic',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Reason'),
      'GP visit',
    );
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('GP visit'), findsWidgets);

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.text('GP visit'), findsOneWidget);
  });

  testWidgets('Chris can open the appointment form', (tester) async {
    await _family(tester);
    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add an appointment'));
    await tester.pumpAndSettle();

    expect(find.text('New appointment'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('Reminder on does not ask for notification permission', (
    tester,
  ) async {
    await _owner(tester);
    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Routine check'));
    await tester.pumpAndSettle();

    expect(find.text('Reminder on'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('Reminder off'), findsOneWidget);
    expect(find.textContaining('permission'), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Posting progress stays on the chosen sentence', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final records = _HeldRecords(LocalRecords(prefs));
    await _launch(tester, records: records);
    await tester.tap(find.text('I’m Pamela’s main carer'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Continue as'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ask for help'));
    await tester.pumpAndSettle();

    // Phone height, large text: the three sentences still fit the list.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pump();
    expect(tester.takeException(), isNull);

    const sentence = 'Can someone collect a prescription?';
    final choices = find.ancestor(
      of: find.widgetWithText(ListTile, sentence),
      matching: find.byType(ListView),
    );

    // Hairlines only between the three sentences, as on About.
    expect(
      find.descendant(of: choices, matching: find.byType(Divider)),
      findsNWidgets(2),
    );

    await tester.tap(find.widgetWithText(ListTile, sentence));
    await tester.pump();

    final tile = find.widgetWithText(ListTile, sentence);

    expect(find.text('Posting…'), findsNothing);
    expect(
      find.descendant(
        of: tile,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Posting…'), findsOneWidget);
    expect(tester.widget<ListTile>(tile).onTap, isNull);
    expect(
      tester
          .widget<ListTile>(
            find.widgetWithText(ListTile, 'Who can visit this weekend?'),
          )
          .onTap,
      isNull,
    );

    records.gate.complete();
    await tester.pump();

    expect(find.text('Request posted'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Request posted'),
        matching: find.byType(Announced),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: choices, matching: find.text('Request posted')),
      findsNothing,
    );

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Ask for help'), findsNothing);
  });

  // Save must stay above the IME, like the diary composer.
  testWidgets('appointment Save stays above the keyboard', (tester) async {
    await _owner(tester);
    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add an appointment'));
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.viewInsets = const FakeViewPadding(bottom: 1300);
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();

    expect(find.text('Save').hitTestable(), findsOneWidget);
  });

  // Heading and action stack so large text does not share one crowded row.
  testWidgets('Family section actions sit under their headings', (tester) async {
    await _owner(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();

    // ListView builds lazily; large text pushes Coming up off-screen.
    final board = find.descendant(
      of: find.byType(FamilyScreen),
      matching: find.byType(ListView),
    );
    await tester.dragUntilVisible(
      find.text('Coming up'),
      board,
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();

    final coming = tester.getTopLeft(find.text('Coming up'));
    final add = tester.getTopLeft(find.text('Add an appointment'));
    expect(add.dy, greaterThan(coming.dy));

    await tester.dragUntilVisible(
      find.text('Ask for help'),
      board,
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();

    final help = tester.getTopLeft(find.text('Where help would matter'));
    final ask = tester.getTopLeft(find.text('Ask for help'));
    expect(ask.dy, greaterThan(help.dy));
    expect(tester.takeException(), isNull);
  });

  // Request copy is one node; I can help / Remove stay separate buttons.
  testWidgets('request actions are separate from the request body', (
    tester,
  ) async {
    await _family(tester);
    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();

    const open = 'Can someone take Mum to her appointment?';
    final body = find.text(open);
    final help = find.text('I can help').first;

    expect(tester.getSemantics(body).id, isNot(tester.getSemantics(help).id));
    expect(tester.getSemantics(help).flagsCollection.isButton, isTrue);
    expect(
      find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Divider),
      ),
      findsAtLeastNWidgets(1),
    );
  });

  testWidgets('staff deep-link to Family lands on Today', (tester) async {
    await _launch(tester);
    await tester.tap(find.text('I’m a support worker'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Jordan'));
    await tester.pumpAndSettle();
    for (final digit in ['2', '5', '8', '0']) {
      await tester.tap(find.widgetWithText(OutlinedButton, digit));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('Family'), findsNothing);
    expect(find.textContaining('porridge'), findsWidgets);
  });
}

/// Pauses the household write so a test can see the posting row.
class _HeldRecords implements RecordPort {
  _HeldRecords(this._inner);

  final RecordPort _inner;
  final Completer<void> gate = Completer<void>();

  @override
  Future<PocketState> load() {
    return _inner.load();
  }

  @override
  Future<PocketState> commit(CareCommand command) async {
    await gate.future;

    return _inner.commit(command);
  }
}
