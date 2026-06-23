import 'dart:async' as async;

import 'package:zeroxkey_http/zeroxkey_http.dart' show ZeroXKeyRequestError;

import '../errors/exceptions.dart';

/// Translates failures raised below the repository boundary into the unified
/// [ZeroXKeyException] hierarchy.
///
/// - Wire-level [ZeroXKeyRequestError] (non-200) -> [ApiException]
/// - Already-mapped [ZeroXKeyException] -> rethrown unchanged
/// - [async.TimeoutException] -> [TimeoutException]
/// - anything else -> [NetworkException]
///
/// Errors are never swallowed: every path either rethrows a typed exception or
/// wraps the original cause.
class ApiErrorMapper {
  const ApiErrorMapper();

  Never map(Object error, [StackTrace? stackTrace]) {
    if (error is ZeroXKeyException) {
      throw error;
    }
    if (error is ZeroXKeyRequestError) {
      throw ApiException.fromRequestError(error);
    }
    if (error is async.TimeoutException) {
      throw TimeoutException(error.message ?? 'Request timed out');
    }
    throw NetworkException('Unexpected transport failure: $error',
        cause: error);
  }

  /// Runs [action], mapping any thrown error through [map].
  Future<T> guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      map(error, stackTrace);
    }
  }
}
