import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../adapters/http/api_client.dart';
import '../adapters/http/http_auth.dart';
import '../adapters/http/http_files.dart';
import '../adapters/http/http_model.dart';
import '../adapters/http/http_records.dart';
import '../adapters/local/local_auth.dart';
import '../adapters/local/local_files.dart';
import '../adapters/local/local_model.dart';
import '../adapters/local/local_notify.dart';
import '../adapters/local/local_records.dart';
import '../adapters/local/local_scan.dart';
import 'desk.dart';

/// Compile-time API root. Empty (default) keeps on-device adapters.
const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

/// True when [root] (after slash strip) is non-empty.
bool usesHttp(String root) => normalizeApiRoot(root).isNotEmpty;

/// The only place that chooses local or HTTP.
/// Browsers have no folder, so local files go to browser storage.
/// [apiUrl] overrides the define (tests). [client] injects a fake HTTP client.
CareDesk composeDesk(
  SharedPreferences prefs, {
  String? apiUrl,
  ApiClient? client,
}) {
  final root = normalizeApiRoot(apiUrl ?? apiBaseUrl);

  if (!usesHttp(root)) {
    final ByteShelf shelf = kIsWeb
        ? PrefsShelf(prefs)
        : DiskShelf(getApplicationSupportDirectory);

    return CareDesk(
      LocalAuth(prefs),
      LocalRecords(prefs),
      const LocalModel(),
      LocalFiles(shelf),
      notify: LocalNotify(),
      scan: const LocalScan(),
    );
  }

  final api = client ?? HttpApiClient(root);

  // Notify and scan stay on-device; the architecture HTTP table omits them.
  return CareDesk(
    HttpAuth(api),
    HttpRecords(api),
    HttpModel(api),
    HttpFiles(api),
    notify: LocalNotify(),
    scan: const LocalScan(),
  );
}
