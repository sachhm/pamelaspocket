import '../../ports/scan_port.dart';

/// Demo household token encoded in the owner QR on More.
const householdToken = 'pamela-household';

/// Stand-in for the camera. Always returns the demo token (no cancel path).
class LocalScan implements ScanPort {
  const LocalScan();

  @override
  Future<({ScanStatus status, String? token})> capture() async {
    return (status: ScanStatus.ok, token: householdToken);
  }
}
