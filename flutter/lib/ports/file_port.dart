import 'dart:typed_data';

import '../domain/enums.dart';

/// A stored photo, voice clip, or document. Records keep only the id.
typedef StoredFile = ({String id, FileKind kind, String label});

/// Bytes stay behind this port.
abstract interface class FilePort {
  Future<StoredFile> put(FileKind kind, String label, Uint8List bytes);

  /// Null when nothing is stored under [id].
  Future<Uint8List?> read(String id);
}
