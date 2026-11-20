import '../../domain/codec.dart';
import '../../domain/commands.dart';
import '../../domain/records.dart';
import '../../ports/record_port.dart';
import 'api_client.dart';

/// Household record over `/v1/records`.
class HttpRecords implements RecordPort {
  HttpRecords(this._client);

  final ApiClient _client;

  @override
  Future<PocketState> load() async {
    return decodeState(await _client.get('/v1/records'));
  }

  @override
  Future<PocketState> commit(CareCommand command) async {
    final body = await _client.post('/v1/records/commands', {
      'command': encodeCommand(command),
    });

    return decodeState(body);
  }
}
