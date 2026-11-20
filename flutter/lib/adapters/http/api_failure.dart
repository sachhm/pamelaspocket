/// Remote call failed. [status] `0` means the network never answered.
class ApiFailure implements Exception {
  const ApiFailure(this.status, [this.message = _defaultMessage]);

  static const _defaultMessage = 'The care service did not answer.';

  final int status;
  final String message;

  @override
  String toString() => 'ApiFailure($status: $message)';
}
