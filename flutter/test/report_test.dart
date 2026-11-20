import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket/adapters/local/local_auth.dart';
import 'package:pocket/adapters/local/local_files.dart';
import 'package:pocket/adapters/local/local_model.dart';
import 'package:pocket/adapters/local/local_notify.dart';
import 'package:pocket/adapters/local/local_records.dart';
import 'package:pocket/app.dart';
import 'package:pocket/care/desk.dart';
import 'package:pocket/domain/auth.dart';
import 'package:pocket/domain/enums.dart';
import 'package:pocket/session/pocket_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _launch(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1170, 9000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final prefs = await SharedPreferences.getInstance();
  final desk = CareDesk(
    LocalAuth(prefs),
    LocalRecords(prefs),
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

Future<void> _staff(WidgetTester tester) async {
  await _launch(tester);
  await tester.tap(find.text('I’m a support worker'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ChoiceChip, 'Jordan'));
  await tester.pumpAndSettle();

  for (final digit in demoPin.split('')) {
    await tester.tap(find.widgetWithText(OutlinedButton, digit));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('pasted report shows summary chip and original', (tester) async {
    await _owner(tester);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a report'));
    await tester.pumpAndSettle();

    const original =
        'Pamela walked in the garden this morning. She rested after lunch. '
        'Blood pressure was steady.';

    await tester.enterText(
      find.widgetWithText(TextField, 'Title'),
      'Garden note',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Report text'),
      original,
    );
    await tester.tap(find.text('Save report'));
    await tester.pumpAndSettle();

    expect(find.text('AI summary'), findsOneWidget);
    expect(
      find.text(
        'Pamela walked in the garden this morning. She rested after lunch.',
      ),
      findsOneWidget,
    );
    expect(find.text(original), findsOneWidget);
    expect(find.textContaining('Blood pressure was steady.'), findsOneWidget);
  });

  testWidgets('staff More shows sign out without reports', (tester) async {
    await _staff(tester);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Reports'), findsNothing);
    expect(find.text('Add a report'), findsNothing);
    expect(find.text('Nurse visit'), findsNothing);
  });

  testWidgets('family can add a report', (tester) async {
    await _family(tester);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('Add a report'), findsOneWidget);
    await tester.tap(find.text('Add a report'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Title'),
      'Chris note',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Report text'),
      'Visited Mum. She was cheerful.',
    );
    await tester.tap(find.text('Save report'));
    await tester.pumpAndSettle();

    expect(find.text('AI summary'), findsOneWidget);
    expect(find.text('Visited Mum. She was cheerful.'), findsWidgets);
  });

  test('file-only report summarises as attached document', () async {
    final prefs = await SharedPreferences.getInstance();
    final files = LocalFiles(PrefsShelf(prefs));
    final desk = CareDesk(
      LocalAuth(prefs),
      LocalRecords(prefs),
      const LocalModel(),
      files,
      notify: LocalNotify(),
    );
    await desk.load();
    await desk.signIn(Role.owner, emailFor(Role.owner), demoPassword);

    final stored = await desk.storeFile(
      FileKind.document,
      'Scan',
      Uint8List.fromList([1, 2, 3]),
    );

    final next = await desk.addReport(
      title: 'Scan only',
      author: 'Alex',
      note: '',
      original: '',
      fileId: stored!.id,
    );

    expect(next, isNotNull);
    expect(next!.reports.first.summary, 'The original document is attached.');
    expect(next.reports.first.original, isEmpty);
  });
}
