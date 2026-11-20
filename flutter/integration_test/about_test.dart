import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pocket/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

const _hold = Duration(seconds: 6);
const _pier = 'Fremantle, in a weatherboard house near the pier.';
const _leaving = 'Gets anxious when it is time to go out.';
const _phone = 'Becomes upset when someone uses their phone.';

/// Stands in for the system photo sheet, which a test cannot tap. The chip,
/// the file port, and the timeline all run for real.
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
      name: 'harbour.png',
    );
  }
}

// A 400×300 olive-and-petal picture, so the timeline has something to show.
Future<List<int>> _picture() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 400, 300),
    Paint()..color = const Color(0xFF839073),
  );
  canvas.drawCircle(
    const Offset(200, 150),
    90,
    Paint()..color = const Color(0xFFF8DBC9),
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

// Lists only report what is on screen, so scroll the visible list first.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      100,
      scrollable: find.byType(Scrollable).hitTestable().first,
    );
  }

  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

// Slice 4 Done when: continue the story saves one answer and returns, an
// observation lands on the card, the suggestion is AI and quotes a line or
// says "No pattern yet.", and a life prompt keeps a photo.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('About path on a phone', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    ImagePickerPlatform.instance = _FakePicker(await _picture());

    await app.main();
    await tester.pumpAndSettle();
    await _tap(tester, find.text('I’m Pamela’s main carer'));
    await _tap(tester, find.textContaining('Continue as'));
    await _tap(tester, find.text('About'));
    await _shot(tester, 'about');

    await _tap(tester, find.text('Continue the story'));
    expect(find.text('Where did Pamela grow up?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), _pier);
    await tester.pump();
    await _tap(tester, find.text('Add photo'));
    await _shot(tester, 'ask');

    await _tap(tester, find.text('Save'));
    expect(find.text(_pier), findsOneWidget);
    expect(find.bySemanticsLabel('Photo with this memory'), findsOneWidget);
    await _shot(tester, 'about_saved');

    await _tap(tester, find.text(_leaving));
    expect(find.text('No pattern yet.'), findsOneWidget);
    await _shot(tester, 'works_leaving');

    await tester.enterText(find.byType(TextField), 'Coat out after lunch.');
    await tester.pump();
    await _tap(tester, find.text('Add'));
    expect(find.text('Alex: Coat out after lunch.'), findsOneWidget);
    await _shot(tester, 'works_added');

    await tester.pageBack();
    await tester.pumpAndSettle();
    await _tap(tester, find.text(_phone));
    expect(find.text('AI suggestion'), findsOneWidget);
    expect(find.textContaining('$_phone Jordan:'), findsOneWidget);
    await _shot(tester, 'works_phone');
  });
}
