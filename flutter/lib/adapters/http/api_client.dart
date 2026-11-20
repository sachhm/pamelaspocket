import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/codec.dart';
import 'api_failure.dart';

/// JSON GET/POST against the care API. Paths are the contract a backend implements.
abstract interface class ApiClient {
  Future<Json> get(String path);

  Future<Json> post(String path, Json body);
}

/// Live client. Base has no trailing slash; paths start with `/v1/…`.
class HttpApiClient implements ApiClient {
  HttpApiClient(this.root, {http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final String root;
  final http.Client _http;

  static const _headers = {
    'accept': 'application/json',
    'content-type': 'application/json',
  };

  @override
  Future<Json> get(String path) => _send('GET', path, null);

  @override
  Future<Json> post(String path, Json body) => _send('POST', path, body);

  Future<Json> _send(String method, String path, Json? body) async {
    final uri = Uri.parse('$root$path');
    late final http.Response response;

    try {
      response = method == 'GET'
          ? await _http.get(uri, headers: _headers)
          : await _http.post(
              uri,
              headers: _headers,
              body: jsonEncode(body),
            );
    } on Object {
      throw const ApiFailure(0, 'The care service could not be reached.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiFailure(
        response.statusCode,
        'The care service rejected the request.',
      );
    }

    if (response.body.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw const ApiFailure(0);
    }

    return Map<String, Object?>.from(decoded);
  }
}

/// Strip trailing slashes so `/v1/…` paths join cleanly.
String normalizeApiRoot(String raw) {
  return raw.replaceAll(RegExp(r'/+$'), '');
}
