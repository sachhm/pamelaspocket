import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:pocket/adapters/local/local_auth.dart';
import 'package:pocket/adapters/local/local_files.dart';
import 'package:pocket/adapters/local/local_model.dart';
import 'package:pocket/adapters/local/local_records.dart';
import 'package:pocket/app.dart';
import 'package:pocket/care/desk.dart';
import 'package:pocket/session/pocket_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _grewUp = 'Fremantle, in a weatherboard house near the harbour.';
const _phone = 'Becomes upset when someone uses their phone.';
const _leaving = 'Gets anxious when it is time to go out.';

// In the browser runner XFile reads through a Blob that never resolves
// under the fake clock, so the picked photo never arrives.
const _browserPick = kIsWeb;

/// Stands in for the system photo sheet, which a widget test cannot open.
class _FakePicker extends ImagePickerPlatform {
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    return XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'pier.png');
  }
}

/// Same as [_FakePicker], but waits so the busy chip can be asserted.
class _SlowPicker extends ImagePickerPlatform {
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    return XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'pier.png');
  }
}

Finder _image(String label) {
  return find.byWidgetPredicate((w) => w is Image && w.semanticLabel == label);
}

Future<void> _launch(WidgetTester tester) async {
  // A tall phone, so all of About is laid out.
  tester.view.physicalSize = const Size(1170, 15000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final prefs = await SharedPreferences.getInstance();
  final desk = CareDesk(
    LocalAuth(prefs),
    LocalRecords(prefs),
    const LocalModel(),
    LocalFiles(PrefsShelf(prefs)),
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
  await _about(tester);
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
  await _about(tester);
}

Future<void> _about(WidgetTester tester) async {
  await tester.tap(find.text('About'));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('About is four sections on one scroll', (tester) async {
    await _owner(tester);

    for (final heading in ['Life', 'Personality', 'Routines', 'What works']) {
      expect(find.text(heading), findsOneWidget);
    }
    expect(find.text('1948'), findsOneWidget);
    expect(find.text(_grewUp), findsOneWidget);
    expect(find.text('Silly mix-ups, and that rabbit story.'), findsOneWidget);
    expect(find.text(_phone), findsOneWidget);
  });

  testWidgets('no rule above the first section', (tester) async {
    await _owner(tester);

    final life = tester.getRect(find.text('Life'));
    final rules = find.byType(Divider).evaluate().map(
      (e) => (e.renderObject! as RenderBox).paintBounds.shift(
        (e.renderObject! as RenderBox).localToGlobal(Offset.zero),
      ),
    );

    expect(rules.where((r) => r.bottom <= life.top), isEmpty);
  });

  testWidgets('staff read About with no edit controls', (tester) async {
    await _staff(tester);

    expect(find.text(_grewUp), findsOneWidget);
    expect(find.text('Continue the story'), findsNothing);

    await _tap(tester, _grewUp);
    expect(find.text('Save'), findsNothing);
    expect(find.text(_grewUp), findsOneWidget);
  });

  testWidgets('continue the story saves one answer and returns', (
    tester,
  ) async {
    await _owner(tester);

    await _tap(tester, 'Continue the story');
    expect(find.text('Where did Pamela grow up?'), findsOneWidget);
    expect(find.text(_grewUp), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Fremantle, by the pier.');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Life'), findsOneWidget);
    expect(find.text('Fremantle, by the pier.'), findsOneWidget);
    expect(find.text(_grewUp), findsNothing);
  });

  testWidgets('a filled prompt opens on its own', (tester) async {
    await _owner(tester);

    await _tap(tester, 'Silly mix-ups, and that rabbit story.');

    expect(find.text('What makes her laugh?'), findsOneWidget);
  });

  testWidgets('an observation appears on the card', (tester) async {
    await _staff(tester);
    await _tap(tester, _leaving);

    await tester.enterText(find.byType(TextField), 'Coat by the door helped.');
    await tester.pump();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Jordan: Coat by the door helped.'), findsOneWidget);
    expect(find.text('Coat by the door helped.'), findsNothing);
  });

  testWidgets('the suggestion is AI and quotes a line', (tester) async {
    await _owner(tester);
    await _tap(tester, _phone);

    expect(find.text('AI suggestion'), findsOneWidget);
    expect(
      find.textContaining('$_phone Jordan: Stepping into the hall'),
      findsOneWidget,
    );
  });

  testWidgets('one note is no pattern yet', (tester) async {
    await _owner(tester);
    await _tap(tester, _leaving);

    expect(find.text('AI suggestion'), findsOneWidget);
    expect(find.text('No pattern yet.'), findsOneWidget);
  });

  testWidgets('a life prompt keeps a photo', (tester) async {
    ImagePickerPlatform.instance = _FakePicker();
    await _owner(tester);
    await _tap(tester, _grewUp);

    await tester.tap(find.text('Add photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Life'), findsOneWidget);
    expect(_image('Photo with this memory'), findsOneWidget);
  }, skip: _browserPick);

  // Layout: undated life rows must not keep a blank year column.
  testWidgets('an undated life row sits flush with the page edge', (
    tester,
  ) async {
    await _owner(tester);

    const people = 'Who are the significant people in her life?';
    const where = 'Where did Pamela grow up?';

    expect(
      tester.getTopLeft(find.text(people)).dx,
      lessThan(tester.getTopLeft(find.text(where)).dx),
    );
  });

  // Adapt: the observation field stays above the keyboard while typing.
  testWidgets('the observation field stays above the keyboard', (tester) async {
    await _owner(tester);
    await _tap(tester, _leaving);

    // Phone height with the keyboard up.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.viewInsets = const FakeViewPadding(bottom: 1300);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    await tester.tap(field);
    await tester.pumpAndSettle();

    expect(field.hitTestable(), findsOneWidget);
  });

  // Harden: VoiceOver hears the suggestion when it first appears.
  testWidgets('the suggestion is announced when it arrives', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(supportsAnnounce: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await _owner(tester);
    await _tap(tester, _leaving);

    expect(
      tester.takeAnnouncements(),
      contains(isAccessibilityAnnouncement('No pattern yet.')),
    );
  });

  // Polish: editable prompts are ListTiles, like Today and What works.
  testWidgets('a life prompt is a list tile', (tester) async {
    await _owner(tester);

    expect(
      find.ancestor(
        of: find.text('Where did Pamela grow up?'),
        matching: find.byType(ListTile),
      ),
      findsOneWidget,
    );
  });

  testWidgets('adding a photo shows a busy chip', (tester) async {
    // A slow pick so "Adding…" is on screen for a frame.
    ImagePickerPlatform.instance = _SlowPicker();
    await _owner(tester);
    await _tap(tester, _grewUp);

    await tester.tap(find.text('Add photo'));
    await tester.pump();

    expect(find.text('Adding…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Photo added'), findsOneWidget);
  }, skip: _browserPick);
}
