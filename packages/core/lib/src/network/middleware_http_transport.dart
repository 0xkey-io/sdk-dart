import 'dart:async' as async;
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:zeroxkey_http/zeroxkey_http.dart'
    show HttpTransport, HttpResponse;

import '../errors/exceptions.dart';
import 'retry_policy.dart';

/// Generates correlation ids for request tracing.
typedef TraceIdGenerator = String Function();

/// Decorates an inner [HttpTransport] with cross-cutting concerns:
/// request tracing, bounded timeouts, exponential-backoff retries on connection
/// errors, and translation of raw transport failures into the core exception
/// hierarchy.
///
/// It does not interpret HTTP status codes or response bodies — that remains the
/// generated client's job, keeping the API protocol untouched.
class MiddlewareHttpTransport implements HttpTransport {
  final HttpTransport _inner;
  final RetryPolicy retryPolicy;
  final Duration? timeout;
  final String traceHeaderName;
  final TraceIdGenerator _traceIdGenerator;

  MiddlewareHttpTransport(
    this._inner, {
    this.retryPolicy = const RetryPolicy(),
    this.timeout,
    this.traceHeaderName = 'X-Trace-Id',
    TraceIdGenerator? traceIdGenerator,
  }) : _traceIdGenerator = traceIdGenerator ?? _defaultTraceId;

  @override
  Future<HttpResponse> post({
    required String url,
    required String body,
    required Map<String, String> headers,
    Duration? timeout,
  }) async {
    final effectiveTimeout = timeout ?? this.timeout;
    final tracedHeaders = <String, String>{
      traceHeaderName: _traceIdGenerator(),
      ...headers,
    };

    var attempt = 0;
    while (true) {
      attempt++;
      try {
        return await _inner.post(
          url: url,
          body: body,
          headers: tracedHeaders,
          timeout: effectiveTimeout,
        );
      } on async.TimeoutException {
        // A timeout is indeterminate: the server may have processed the request,
        // so we never retry it to avoid duplicate, non-idempotent activities.
        throw const TimeoutException('Request timed out');
      } on http.ClientException catch (e) {
        // Connection-level failure: the request did not reach the server, so a
        // retry is safe.
        if (retryPolicy.shouldRetry(attempt)) {
          await Future<void>.delayed(retryPolicy.delayForAttempt(attempt));
          continue;
        }
        throw NetworkException(
          'Network request failed after $attempt attempt(s): ${e.message}',
          cause: e,
        );
      }
    }
  }

  static String _defaultTraceId() {
    final rng = Random();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
