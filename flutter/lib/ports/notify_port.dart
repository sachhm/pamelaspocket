import '../domain/enums.dart';
import '../domain/records.dart';

/// Reminder scheduling. The stand-in stores the flag and never prompts for
/// system permission.
abstract interface class NotifyPort {
  Future<void> set(String appointmentId, When when, Reminder reminder);
}
