import '../domain/commands.dart';
import '../domain/records.dart';

/// The household record. `commit` is the only write and returns the next
/// full state.
abstract interface class RecordPort {
  Future<PocketState> load();

  Future<PocketState> commit(CareCommand command);
}
