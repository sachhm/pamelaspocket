import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pocket/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

const _hold = Duration(seconds: 6);
const _tea = 'She had tea in the garden.';

/// Stands in for the system photo sheet, which a test cannot tap. The chip,
/// the file port, and the leaf all run for real.
class _FakePicker extends ImagePickerPlatform {
  _FakePicker(this._png);

  final List<int> _png;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    return XFile.fromData(
      Uint8List.fromList(_png),
      mimeType: 'image/png',
      name: 'garden.png',
    );
  }
}

// A 400×300 petal-and-olive picture, drawn so the leaf has something to show.
Future<List<int>> _picture() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 400, 300),
    Paint()..color = const Color(0xFFF8DBC9),
  );
  canvas.drawCircle(
    const Offset(200, 150),
    90,
    Paint()..color = const Color(0xFF839073),
  );
  final image = await recorder.endRecording().toImage(400, 300);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);

  return data!.buffer.asUint8List();
}

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  debugPrint('SHOT:$name');
  await Future<void>.delayed(_hold);
}

// Lists only report what is on screen, so scroll the target into view first.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      100,
      scrollable: find.byType(Scrollable).first,
    );
  }

  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

// Slice 3 Done when: a typed update rewrites the handover as AI, the voice
// chip shows the lemon line, and a photo is stored and shown on the leaf.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('diary path on a phone', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    ImagePickerPlatform.instance = _FakePicker(await _picture());

    await app.main();
    await tester.pumpAndSettle();
    await _tap(tester, find.text('I’m Pamela’s main carer'));
    await _tap(tester, find.textContaining('Continue as'));
    await _shot(tester, 'today_seed');

    await _tap(tester, find.text('Add update'));
    await tester.enterText(find.widgetWithText(TextField, 'Note'), _tea);
    await tester.pump();
    await _tap(tester, find.text('Save'));
    expect(find.text('Update saved'), findsOneWidget);
    expect(find.text('AI summary'), findsOneWidget);
    expect(find.text('From Alex'), findsNothing);
    await _shot(tester, 'today_saved');

    await _tap(tester, find.text('Add update'));

    await _tap(tester, find.text('Voice note'));
    expect(find.text('Sample transcript', skipOffstage: false), findsOneWidget);
    await _shot(tester, 'voice');
    await _tap(tester, find.text('Add photo'));
    expect(find.text('Photo added', skipOffstage: false), findsOneWidget);
    await _shot(tester, 'composer');

    await _tap(tester, find.text('Save'));
    await _tap(
      tester,
      find.text('She said the lemons from Joan were the best this year.'),
    );
    expect(find.bySemanticsLabel('Photo with this update'), findsOneWidget);
    await _shot(tester, 'leaf');
  });
}
