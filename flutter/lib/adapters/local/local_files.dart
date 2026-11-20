import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/enums.dart';
import '../../domain/time.dart';
import '../../ports/file_port.dart';

const _fileKey = 'pamelas-pocket.file.';

/// Where [LocalFiles] keeps bytes: a folder on a phone, browser storage on
/// the web, which has no folder to write to.
abstract interface class ByteShelf {
  Future<void> write(String id, Uint8List bytes);

  Future<Uint8List?> read(String id);
}

/// Keeps the bytes, unlike the Expo adapter, so a photo can render.
class LocalFiles implements FilePort {
  LocalFiles(this._shelf, {this._clock = DateTime.now});

  final ByteShelf _shelf;
  final DateTime Function() _clock;

  @override
  Future<StoredFile> put(FileKind kind, String label, Uint8List bytes) async {
    final id = makeId(kind.name, _clock().microsecondsSinceEpoch);
    await _shelf.write(id, bytes);

    return (id: id, kind: kind, label: label);
  }

  @override
  Future<Uint8List?> read(String id) {
    return _shelf.read(id);
  }
}

/// One file per id under [_root], e.g. the app support directory.
class DiskShelf implements ByteShelf {
  DiskShelf(this._root);

  final Future<Directory> Function() _root;

  @override
  Future<void> write(String id, Uint8List bytes) async {
    final file = await _file(id);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  }

  @override
  Future<Uint8List?> read(String id) async {
    final file = await _file(id);

    if (!await file.exists()) {
      return null;
    }

    return file.readAsBytes();
  }

  Future<File> _file(String id) async {
    final root = await _root();

    return File('${root.path}/files/$id');
  }
}

/// Base64 under one key per file. Web only; photos are resized before they
/// get here, so they fit the browser's storage.
class PrefsShelf implements ByteShelf {
  PrefsShelf(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<void> write(String id, Uint8List bytes) async {
    await _prefs.setString('$_fileKey$id', base64Encode(bytes));
  }

  @override
  Future<Uint8List?> read(String id) async {
    final raw = _prefs.getString('$_fileKey$id');

    if (raw == null) {
      return null;
    }

    return base64Decode(raw);
  }
}
