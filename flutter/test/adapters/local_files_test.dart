import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket/adapters/local/local_files.dart';
import 'package:pocket/domain/enums.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _bytes = Uint8List.fromList([1, 2, 3, 250]);

void main() {
  test('disk shelf keeps the bytes under the root', () async {
    final root = await Directory.systemTemp.createTemp('pocket');
    addTearDown(() => root.delete(recursive: true));
    final files = LocalFiles(DiskShelf(() async => root));

    final stored = await files.put(FileKind.photo, 'Garden', _bytes);

    expect(stored.id, startsWith('photo-'));
    expect(stored.label, 'Garden');
    expect(await files.read(stored.id), _bytes);
    expect(await files.read('photo-missing'), isNull);
  }, testOn: 'vm');

  test('browser shelf keeps the bytes in storage', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final files = LocalFiles(PrefsShelf(prefs));

    final stored = await files.put(FileKind.photo, 'Garden', _bytes);
    final reopened = LocalFiles(PrefsShelf(prefs));

    expect(await reopened.read(stored.id), _bytes);
    expect(await reopened.read('photo-missing'), isNull);
  });
}
