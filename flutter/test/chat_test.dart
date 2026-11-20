import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket/adapters/local/local_auth.dart';
import 'package:pocket/adapters/local/local_files.dart';
import 'package:pocket/adapters/local/local_model.dart';
import 'package:pocket/adapters/local/local_records.dart';
import 'package:pocket/app.dart';
import 'package:pocket/care/desk.dart';
import 'package:pocket/domain/chat.dart';
import 'package:pocket/domain/records.dart';
import 'package:pocket/ports/model_port.dart';
import 'package:pocket/session/pocket_scope.dart';
import 'package:pocket/ui/announced.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _breakfast = 'What does she usually have for breakfast?';
const _dose = 'What is her dose?';

// Before the seeded 7 am and 8 am notes: clock order would put new ones first.
final _pastMidnight = DateTime(2026, 11, 20, 0, 5);

Future<void> _launch(
  WidgetTester tester, {
  ModelPort model = const LocalModel(),
  DateTime Function() clock = DateTime.now,
}) async {
  tester.view.physicalSize = const Size(1170, 9000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final prefs = await SharedPreferences.getInstance();
  final desk = CareDesk(
    LocalAuth(prefs),
    LocalRecords(prefs),
    model,
    LocalFiles(PrefsShelf(prefs)),
    clock: clock,
  );
  final scope = PocketScope(desk);
  await scope.load();

  await tester.pumpWidget(PocketApp(scope: scope));
  await tester.pumpAndSettle();
}

/// Holds [answerCare] until [gate] completes so the busy frame is visible.
class _GatedModel implements ModelPort {
  _GatedModel(this._inner, this.gate);

  final ModelPort _inner;
  final Completer<void> gate;

  @override
  Future<String> summariseDiary(List<DiaryEntry> entries) {
    return _inner.summariseDiary(entries);
  }

  @override
  Future<String> summariseReport(String original) {
    return _inner.summariseReport(original);
  }

  @override
  Future<String> suggestPattern(WorkCard card, List<DiaryEntry> entries) {
    return _inner.suggestPattern(card, entries);
  }

  @override
  Future<Answer> answerCare(String text, List<DiaryEntry> entries) async {
    await gate.future;

    return _inner.answerCare(text, entries);
  }

  @override
  Future<String> guideReply(int spokenCount) {
    return _inner.guideReply(spokenCount);
  }
}

Future<void> _owner(
  WidgetTester tester, {
  ModelPort? model,
  DateTime Function() clock = DateTime.now,
}) async {
  await _launch(tester, model: model ?? const LocalModel(), clock: clock);
  await tester.tap(find.text('I’m Pamela’s main carer'));
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
  for (final digit in ['2', '5', '8', '0']) {
    await tester.tap(find.widgetWithText(OutlinedButton, digit));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> _chat(WidgetTester tester) async {
  await tester.tap(find.text('Chat'));
  await tester.pumpAndSettle();
}

Future<void> _ask(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
  await tester.tap(find.text('Send'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('breakfast answers from the notes and shows AI reply', (
    tester,
  ) async {
    await _owner(tester);
    await _chat(tester);
    await _ask(tester, _breakfast);

    expect(find.text('AI reply'), findsWidgets);
    expect(find.textContaining('porridge'), findsOneWidget);
    expect(find.text('Pocket Guide'), findsOneWidget);
    expect(find.text('Private. Not part of the diary.'), findsOneWidget);
  });

  testWidgets('unknown dose lets staff ask Alex or Chris', (tester) async {
    await _staff(tester);
    await _chat(tester);

    expect(find.text('Pocket Guide'), findsNothing);
    await _ask(tester, _dose);

    expect(find.text('Ask Alex or Chris'), findsOneWidget);
    await tester.tap(find.text('Ask Alex or Chris'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chris'));
    await tester.pumpAndSettle();

    expect(find.text('Sent to Chris'), findsOneWidget);
  });

  testWidgets('guide text never appears on Today', (tester) async {
    await _owner(tester);
    await _chat(tester);
    await tester.tap(find.text('Pocket Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(guideHandover));
    await tester.pumpAndSettle();

    expect(find.text(handoverDraft), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    expect(find.text(handoverDraft), findsNothing);
    expect(find.textContaining('Only you can see this'), findsNothing);
  });

  testWidgets('Add to the diary needs confirm, then keeps the draft', (
    tester,
  ) async {
    await _owner(tester);
    await _chat(tester);
    await tester.tap(find.text('Pocket Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(guideHandover));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add to the diary'));
    await tester.pumpAndSettle();
    expect(find.text('Add this to the diary?'), findsOneWidget);

    await tester.tap(find.text('Keep in Guide'));
    await tester.pumpAndSettle();
    expect(find.text(handoverDraft), findsOneWidget);

    await tester.tap(find.text('Add to the diary'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Add to the diary'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(handoverDraft), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.text(handoverDraft), findsWidgets);
  });

  // Ask must be its own semantics node, not merged into the AI bubble.
  testWidgets('Ask action is a separate semantics button', (tester) async {
    await _staff(tester);
    await _chat(tester);
    await _ask(tester, _dose);

    final ask = find.text('Ask Alex or Chris');
    final body = find.textContaining("I don't have that");
    expect(tester.getSemantics(ask).id, isNot(tester.getSemantics(body).id));
    expect(tester.getSemantics(ask).flagsCollection.isButton, isTrue);
  });

  // Busy status must announce; gate the model so Checking stays on screen.
  testWidgets('Checking status is announced', (tester) async {
    final gate = Completer<void>();
    await _owner(tester, model: _GatedModel(const LocalModel(), gate));
    await _chat(tester);
    await tester.enterText(find.byType(TextField), _breakfast);
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pump();

    expect(find.text('Checking Pamela’s notes…'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Checking Pamela’s notes…'),
        matching: find.byType(Announced),
      ),
      findsOneWidget,
    );

    gate.complete();
    await tester.pumpAndSettle();
  });

  // Starter chips must meet the 48 dp target used elsewhere in the app.
  testWidgets('guide starter chips are at least 48 tall', (tester) async {
    await _owner(tester);
    await _chat(tester);
    await tester.tap(find.text('Pocket Guide'));
    await tester.pumpAndSettle();

    final size = tester.getSize(find.widgetWithText(ActionChip, guideHandover));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  // Add must stay outside the bubble merge, same as Ask on Chat.
  testWidgets('Add to the diary is a separate semantics button', (
    tester,
  ) async {
    await _owner(tester);
    await _chat(tester);
    await tester.tap(find.text('Pocket Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(guideHandover));
    await tester.pumpAndSettle();

    final add = find.text('Add to the diary');
    final body = find.text(handoverDraft);
    expect(tester.getSemantics(add).id, isNot(tester.getSemantics(body).id));
    expect(tester.getSemantics(add).flagsCollection.isButton, isTrue);
  });

  // Tab bar must yield the strip above the IME so Chat can send.
  testWidgets('keyboard hides the tab bar on Chat', (tester) async {
    await _owner(tester);
    await _chat(tester);
    expect(find.byType(NavigationBar), findsOneWidget);

    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.viewInsets = const FakeViewPadding(bottom: 1300);
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Send').hitTestable(), findsOneWidget);
  });

  testWidgets('a chat sent after midnight lands last', (tester) async {
    await _owner(tester, clock: () => _pastMidnight);
    await _chat(tester);
    await _ask(tester, _breakfast);

    final asked = tester.getRect(find.text(_breakfast));
    final seeded = tester.getRect(find.text('Where are the spare clothes?'));

    expect(asked.top, greaterThan(seeded.top));
  });

  testWidgets('a guide draft written after midnight lands last', (
    tester,
  ) async {
    await _owner(tester, clock: () => _pastMidnight);
    await _chat(tester);
    await tester.tap(find.text('Pocket Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(guideHandover).last);
    await tester.pumpAndSettle();

    final draft = tester.getRect(find.text(handoverDraft));
    final seeded = tester.getRect(find.textContaining('This space is just'));

    expect(draft.top, greaterThan(seeded.top));
  });

  // Short phone: after a starter, the draft must land in the visible list.
  testWidgets('guide scrolls the new draft into view', (tester) async {
    await _owner(tester);
    await _chat(tester);

    // _launch uses a tall surface; shrink after sign-in so the draft clips.
    tester.view.physicalSize = const Size(1170, 1100);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pocket Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(guideHandover));
    await tester.pumpAndSettle();

    expect(find.text(handoverDraft).hitTestable(), findsOneWidget);
    expect(find.text('Add to the diary').hitTestable(), findsOneWidget);
  });

  // Large text must keep Send reachable on a phone Chat layout.
  testWidgets('text scale 2.0 keeps Chat Send reachable', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _owner(tester);
    await _chat(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Send').hitTestable(), findsOneWidget);
  });
}
