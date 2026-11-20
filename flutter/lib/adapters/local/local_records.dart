import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/apply.dart';
import '../../domain/codec.dart';
import '../../domain/commands.dart';
import '../../domain/records.dart';
import '../../domain/seed.dart';
import '../../ports/record_port.dart';

const recordsKey = 'pamelas-pocket.records.v2';

/// Keeps the household in memory and on device. The first load with nothing
/// saved writes the seed; every commit runs `apply` and saves the result.
class LocalRecords implements RecordPort {
  LocalRecords(this._prefs);

  final SharedPreferences _prefs;
  PocketState? _state;

  @override
  Future<PocketState> load() async {
    final held = _state;

    if (held != null) {
      return held;
    }

    final saved = _read();

    if (saved != null) {
      return _state = saved;
    }

    return _write(createSeed());
  }

  @override
  Future<PocketState> commit(CareCommand command) async {
    return _write(apply(await load(), command));
  }

  // An unreadable save falls back to the seed rather than blocking launch.
  PocketState? _read() {
    final raw = _prefs.getString(recordsKey);

    if (raw == null) {
      return null;
    }

    try {
      return decodeState(jsonDecode(raw) as Json);
    } on Object {
      return null;
    }
  }

  Future<PocketState> _write(PocketState state) async {
    await _prefs.setString(recordsKey, jsonEncode(encodeState(state)));

    return _state = state;
  }
}
