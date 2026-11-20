import '../../domain/enums.dart';
import '../../domain/records.dart';
import '../../ports/notify_port.dart';

/// In-memory reminder flag. No OS schedule, no permission dialog.
class LocalNotify implements NotifyPort {
  final _flags = <String, Reminder>{};

  /// Last stored reminder for tests and debugging.
  Reminder? of(String appointmentId) => _flags[appointmentId];

  @override
  Future<void> set(String appointmentId, When when, Reminder reminder) async {
    _flags[appointmentId] = reminder;
  }
}
