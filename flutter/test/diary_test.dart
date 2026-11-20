import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:pocket/adapters/local/local_auth.dart';
import 'package:pocket/adapters/local/local_files.dart';
import 'package:pocket/adapters/local/local_model.dart';
import 'package:pocket/adapters/local/local_records.dart';
import 'package:pocket/app.dart';
import 'package:pocket/care/desk.dart';
import 'package:pocket/domain/commands.dart';
import 'package:pocket/domain/copy.dart';
import 'package:pocket/domain/records.dart';
import 'package:pocket/ports/model_port.dart';
import 'package:pocket/ports/record_port.dart';
import 'package:pocket/session/pocket_scope.dart';
import 'package:pocket/theme/pocket_theme.dart';
import 'package:pocket/ui/ai_chip.dart';
import 'package:pocket/ui/paper_motion.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tea = 'She had tea in the garden.';
const _garden = 'She hummed along to Vera Lynn while we watered the herbs.';
const _failed = 'The care service did not answer.';

// Afternoon, after every seeded note; morning, before most of them.
final _afternoon = DateTime(2026, 11, 15, 14, 30);
final _morning = DateTime(2026, 11, 15, 7, 5);

/// Loads and saves like the device, but every new entry fails to save.
class _NoNewEntries implements RecordPort {
  _NoNewEntries(this._inner);

  final RecordPort _inner;

  @override
  Future<PocketState> load() => _inner.load();

  @override
  Future<PocketState> commit(CareCommand command) {
    if (command is EntryAdd) {
      throw StateError('offline');
    }

    return _inner.commit(command);
  }
}

/// Stands in for the system photo sheet, which a widget test cannot open.
class _FakePicker extends ImagePickerPlatform {
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    return XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'tea.png');
  }
}

/// A summariser that takes a second, so "Updating…" is on screen.
class _SlowModel implements ModelPort {
  @override
  Future<String> summariseDiary(List<DiaryEntry> entries) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return const LocalModel().summariseDiary(entries);
  }

  @override
  Future<String> summariseReport(String original) {
    return const LocalModel().summariseReport(original);
  }

  @override
  Future<String> suggestPattern(WorkCard card, List<DiaryEntry> entries) {
    return const LocalModel().suggestPattern(card, entries);
  }

  @override
  Future<Answer> answerCare(String text, List<DiaryEntry> entries) {
    return const LocalModel().answerCare(text, entries);
  }

  @override
  Future<String> guideReply(int spokenCount) {
    return const LocalModel().guideReply(spokenCount);
  }
}

// In the browser runner XFile reads through a Blob that never resolves
// under the fake clock, so the picked photo never arrives.
const _browserPick = kIsWeb;

enum _Records { device, failing }

Finder _note() => find.widgetWithText(TextField, 'Note');

Finder _image(String label) {
  return find.byWidgetPredicate((w) => w is Image && w.semanticLabel == label);
}

Future<void> _launch(
  WidgetTester tester, {
  _Records records = _Records.device,
  DateTime? clock,
  ModelPort model = const LocalModel(),
}) async {
  // A tall phone, so all of Today is laid out.
  tester.view.physicalSize = const Size(1170, 7500);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final prefs = await SharedPreferences.getInstance();
  final local = LocalRecords(prefs);
  final desk = CareDesk(
    LocalAuth(prefs),
    records == _Records.failing ? _NoNewEntries(local) : local,
    model,
    LocalFiles(PrefsShelf(prefs)),
    clock: () => clock ?? _afternoon,
  );
  final scope = PocketScope(desk);
  await scope.load();

  await tester.pumpWidget(PocketApp(scope: scope));
  await tester.pumpAndSettle();
}

Future<void> _owner(
  WidgetTester tester, {
  _Records records = _Records.device,
  DateTime? clock,
  ModelPort model = const LocalModel(),
}) async {
  await _launch(tester, records: records, clock: clock, model: model);
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

Future<void> _compose(WidgetTester tester) async {
  await tester.tap(find.text('Add update'));
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester, String body) async {
  await tester.ensureVisible(find.text(body));
  await tester.pumpAndSettle();
  await tester.tap(find.text(body));
  await tester.pumpAndSettle();
}

// Vertical travel of the note that is settling onto Today.
double _slipY(WidgetTester tester) {
  final slip = find.byType(PaperSlip, skipOffstage: false);

  return tester
      .widget<Transform>(
        find.descendant(of: slip, matching: find.byType(Transform)),
      )
      .transform
      .getTranslation()
      .y;
}

// The color a label is painted in, after its button's style applies.
Color? _ink(WidgetTester tester, Finder label) {
  return tester.renderObject<RenderParagraph>(label).text.style?.color;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Today opens with Pamela and the seeded handover from Alex', (
    tester,
  ) async {
    await _owner(tester);

    expect(find.text('Pamela'), findsOneWidget);
    expect(find.text('Handover'), findsOneWidget);
    expect(find.text('From Alex'), findsOneWidget);
    expect(find.text('AI summary'), findsNothing);
    expect(find.text('Next visit'), findsOneWidget);
    expect(find.text(_garden), findsOneWidget);
    expect(find.byType(PaperSlip), findsNothing);
  });

  testWidgets('owner resolves the open question; the strip goes', (
    tester,
  ) async {
    await _owner(tester);

    expect(find.text('1 open question'), findsOneWidget);

    await tester.tap(find.text('Mark resolved'));
    await tester.pumpAndSettle();

    expect(find.text('1 open question'), findsNothing);
  });

  testWidgets('staff see the question without Mark resolved', (tester) async {
    await _staff(tester);

    expect(find.text('1 open question'), findsOneWidget);
    expect(find.text('Mark resolved'), findsNothing);
  });

  testWidgets('a saved update rewrites the handover as AI', (tester) async {
    await _owner(tester);
    await _compose(tester);

    await tester.enterText(_note(), _tea);
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Update saved'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.textContaining(_tea), findsNWidgets(2));
    expect(find.text('AI summary'), findsOneWidget);
    expect(find.text('From Alex'), findsNothing);
  });

  testWidgets('a saved note settles onto the page as the composer leaves', (
    tester,
  ) async {
    await _owner(tester);
    await _compose(tester);
    await tester.enterText(_note(), _tea);
    await tester.pump();
    await tester.tap(find.text('Save'));

    // The row is in the tree under the composer, still held blank.
    await tester.pump();
    await tester.pump();

    final held = find.byType(PaperSlip, skipOffstage: false);
    expect(held, findsOneWidget);
    expect(_slipY(tester), closeTo(-8, 0.1));

    // The pop starts, and the note travels down onto its line.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    final moving = _slipY(tester);
    expect(moving, greaterThan(-8));
    expect(moving, lessThan(0));

    await tester.pumpAndSettle();
    expect(_slipY(tester), 0);
  });

  testWidgets('reduced motion fades the saved note without moving it', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await _owner(tester);
    await _compose(tester);
    await tester.enterText(_note(), _tea);
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    // The platform shortens the fade. The note still must not travel.
    expect(_slipY(tester), 0);
    expect(find.text(_tea, skipOffstage: false), findsWidgets);

    await tester.pumpAndSettle();
    expect(_slipY(tester), 0);
  });

  testWidgets('a morning update leads the handover and the rows', (
    tester,
  ) async {
    await _owner(tester, clock: _morning);
    await _compose(tester);

    await tester.enterText(_note(), _tea);
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final handover = find.textContaining(_tea).first;
    final garden = find.text(_garden);

    expect(tester.widget<Text>(handover).data, startsWith(_tea));
    expect(find.text('Updated 7:05 am'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(_tea).last).dy,
      lessThan(tester.getTopLeft(garden).dy),
    );
  });

  testWidgets('a failed save keeps the composer and the text', (tester) async {
    await _owner(tester, records: _Records.failing);
    await _compose(tester);

    await tester.enterText(_note(), _tea);
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text(_failed), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text(_tea), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('Save waits for something to save', (tester) async {
    await _owner(tester);
    await _compose(tester);

    final save = find.widgetWithText(FilledButton, 'Save');
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    await tester.enterText(_note(), 'Tea.');
    await tester.pump();

    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
  });

  testWidgets('voice inserts the sample under Sample transcript', (
    tester,
  ) async {
    await _owner(tester);
    await _compose(tester);

    await tester.tap(find.text('Voice note'));
    await tester.pumpAndSettle();

    expect(find.text('Sample transcript'), findsOneWidget);
    expect(find.text(sampleVoice), findsOneWidget);
  });

  testWidgets('voice transcript scrolls into view above the keyboard', (
    tester,
  ) async {
    await _owner(tester);
    await _compose(tester);

    // Phone height with the keyboard up.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.viewInsets = const FakeViewPadding(bottom: 1300);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Voice note'));
    await tester.pumpAndSettle();

    expect(find.text('Sample transcript').hitTestable(), findsOneWidget);
  });

  testWidgets('an added photo shows before saving, and can be taken off', (
    tester,
  ) async {
    ImagePickerPlatform.instance = _FakePicker();
    await _owner(tester);
    await _compose(tester);

    await tester.tap(find.text('Add photo'));
    await tester.pumpAndSettle();
    expect(_image('Photo to add'), findsOneWidget);

    await tester.tap(find.text('Photo added'));
    await tester.pumpAndSettle();
    expect(_image('Photo to add'), findsNothing);
  }, skip: _browserPick);

  testWidgets('the leaf decodes the photo at its shown width', (tester) async {
    ImagePickerPlatform.instance = _FakePicker();
    await _owner(tester);
    await _compose(tester);
    await tester.enterText(_note(), _tea);
    await tester.tap(find.text('Add photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await _open(tester, _tea);

    final photo = tester.widget<Image>(_image('Photo with this update'));

    expect(photo.image, isA<ResizeImage>());
  }, skip: _browserPick);

  testWidgets('the AI chip keeps its pill on the petal handover', (
    tester,
  ) async {
    await _owner(tester);
    await _compose(tester);
    await tester.enterText(_note(), _tea);
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final chip = find.byType(AiChip);
    final scheme = Theme.of(tester.element(chip)).colorScheme;
    final pill = tester.widget<DecoratedBox>(
      find.descendant(of: chip, matching: find.byType(DecoratedBox)).first,
    );

    expect((pill.decoration as ShapeDecoration).color, scheme.surface);
  });

  testWidgets('the handover refresh is announced', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(supportsAnnounce: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await _owner(tester, model: _SlowModel());
    await _compose(tester);
    await tester.enterText(_note(), _tea);
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      tester.takeAnnouncements(),
      contains(isAccessibilityAnnouncement('Updating…')),
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Updating…'), findsNothing);
  });

  testWidgets('composer footer names who is saving', (tester) async {
    await _staff(tester);
    await _compose(tester);

    expect(find.textContaining('Saving as Jordan'), findsOneWidget);
  });

  testWidgets('Back with text asks before discarding', (tester) async {
    await _owner(tester);
    await _compose(tester);
    await tester.enterText(_note(), 'Half a thought');
    await tester.pump();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard this update?'), findsOneWidget);

    await tester.tap(find.text('Keep writing'));
    await tester.pumpAndSettle();
    expect(find.text('Half a thought'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('owner edits an entry from its leaf', (tester) async {
    await _owner(tester);
    await _open(tester, _garden);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'She sang in the garden.');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('She sang in the garden.'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
  });

  testWidgets('owner removes an entry after confirming', (tester) async {
    await _owner(tester);
    await _open(tester, _garden);

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Remove this update?'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Remove'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text(_garden), findsNothing);
  });

  testWidgets('Remove is red; Edit and Cancel are not', (tester) async {
    await _owner(tester);
    await _open(tester, _garden);

    expect(_ink(tester, find.text('Remove')), PocketTheme.danger);
    expect(_ink(tester, find.text('Edit')), isNot(PocketTheme.danger));

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);

    expect(
      _ink(tester, find.descendant(of: dialog, matching: find.text('Remove'))),
      PocketTheme.danger,
    );
    expect(
      _ink(tester, find.descendant(of: dialog, matching: find.text('Cancel'))),
      isNot(PocketTheme.danger),
    );
  });

  testWidgets('staff read an entry with no edit controls', (tester) async {
    await _staff(tester);
    await _open(tester, _garden);

    expect(find.text('A lovely moment'), findsOneWidget);
    expect(find.textContaining('Alex'), findsWidgets);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Remove'), findsNothing);
  });
}
