import 'package:zeroxkey_http/zeroxkey_http.dart' show ZeroXKeyRequestError;

/// Root of the SDK exception hierarchy.
///
/// Every failure surfaced by `zeroxkey_core` is a [ZeroXKeyException] subtype so
/// callers can branch on a single, well-defined family instead of catching
/// arbitrary [Exception]s. The wire-level [ZeroXKeyRequestError] (thrown by the
/// generated transport) is intentionally left untouched for backward
/// compatibility and is translated into [ApiException] at the data boundary.
sealed class ZeroXKeyException implements Exception {
  final String message;

  const ZeroXKeyException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// A transport-level failure that prevented a request from completing
/// (connection refused/reset, DNS failure, exhausted retries).
class NetworkException extends ZeroXKeyException {
  final Object? cause;

  const NetworkException(super.message, {this.cause});
}

/// A request exceeded its allotted time budget. The server may or may not have
/// processed it, so callers must treat the outcome as indeterminate.
class TimeoutException extends ZeroXKeyException {
  const TimeoutException(super.message);
}

/// A structured, protocol-level error returned by the API.
///
/// Preserves the wire contract: [code] is the gRPC status code, [details] the
/// optional detail payload — identical to [ZeroXKeyRequestError].
class ApiException extends ZeroXKeyException {
  final int code;
  final List<dynamic>? details;

  const ApiException({
    required this.code,
    required String message,
    this.details,
  }) : super(message);

  /// Adapts the generated transport's [ZeroXKeyRequestError] into the core
  /// hierarchy without altering its semantics.
  factory ApiException.fromRequestError(ZeroXKeyRequestError error) {
    return ApiException(
      code: error.code,
      message: error.message,
      details: error.details,
    );
  }

  @override
  String toString() => 'ApiException($code): $message';
}

/// An authentication/authorization flow failed (invalid OTP, missing session,
/// rejected credential, etc.).
class AuthException extends ZeroXKeyException {
  const AuthException(super.message);
}

/// A signing/crypto operation failed locally (missing key, bundle verification
/// failure, malformed payload).
class SigningException extends ZeroXKeyException {
  const SigningException(super.message);
}

/// A required precondition was not met (e.g. no active session/client).
class StateException extends ZeroXKeyException {
  const StateException(super.message);
}
