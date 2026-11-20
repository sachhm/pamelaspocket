import 'dart:convert';
import 'dart:typed_data';

import '../../domain/enums.dart';
import '../../ports/file_port.dart';
import 'api_client.dart';

/// File bytes over `/v1/files`.
class HttpFiles implements FilePort {
  HttpFiles(this._client);

  final ApiClient _client;

  @override
  Future<StoredFile> put(FileKind kind, String label, Uint8List bytes) async {
    final body = await _client.post('/v1/files', {
      'kind': kind.name,
      'label': label,
      'bytes': base64Encode(bytes),
    });

    return (
      id: body['id']! as String,
      kind: FileKind.values.byName(body['kind']! as String),
      label: body['label']! as String,
    );
  }

  @override
  Future<Uint8List?> read(String id) async {
    final body = await _client.get('/v1/files/$id');
    final raw = body['bytes'];

    if (raw is! String) {
      return null;
    }

    return base64Decode(raw);
  }
}