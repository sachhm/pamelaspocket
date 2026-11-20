/// Result of a household QR capture.
enum ScanStatus { ok, cancelled }

/// Camera scan of the household code. Local stand-in returns the demo token.
abstract interface class ScanPort {
  Future<({ScanStatus status, String? token})> capture();
}
