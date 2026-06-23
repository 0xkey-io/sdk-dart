import 'dart:async' as async;

import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:zeroxkey_core/zeroxkey_core.dart';
import 'package:zeroxkey_http/zeroxkey_http.dart'
    show HttpTransport, HttpResponse;

/// Inner transport whose behavior is scripted per attempt.
class _ScriptedTransport implements HttpTransport {
  final List<Object> script; // HttpResponse to return or Object to throw
  final List<Map<String, String>> capturedHeaders = [];
  int calls = 0;

  _ScriptedTransport(this.script);

  @override
  Future<HttpResponse> post({
    required String url,
    required String body,
    required Map<String, String> headers,
    Duration? timeout,
  }) async {
    capturedHeaders.add(Map.of(headers));
    final step = script[calls];
    calls++;
    if (step is HttpResponse) return step;
    throw step;
  }
}

void main() {
  group('MiddlewareHttpTransport', () {
    test('adds a trace id header and passes through a successful response',
        () async {
      final inner =
          _ScriptedTransport([const HttpResponse(statusCode: 200, body: '{}')]);
      final transport = MiddlewareHttpTransport(inner);

      final res = await transport.post(url: 'u', body: 'b', headers: {});

      expect(res.statusCode, 200);
      expect(inner.capturedHeaders.single.containsKey('X-Trace-Id'), isTrue);
    });

    test('does not overwrite caller-provided headers', () async {
      final inner =
          _ScriptedTransport([const HttpResponse(statusCode: 200, body: '{}')]);
      final transport = MiddlewareHttpTransport(inner);

      await transport.post(url: 'u', body: 'b', headers: {'X-Stamp': 'abc'});

      expect(inner.capturedHeaders.single['X-Stamp'], 'abc');
    });

    test('retries connection errors then succeeds', () async {
      final inner = _ScriptedTransport([
        http.ClientException('connection reset'),
        const HttpResponse(statusCode: 200, body: 'ok'),
      ]);
      final transport = MiddlewareHttpTransport(
        inner,
        retryPolicy: const RetryPolicy(
          maxAttempts: 3,
          baseDelay: Duration(milliseconds: 1),
        ),
      );

      final res = await transport.post(url: 'u', body: 'b', headers: {});

      expect(res.body, 'ok');
      expect(inner.calls, 2);
    });

    test('throws NetworkException after exhausting retries', () async {
      final inner = _ScriptedTransport([
        http.ClientException('reset'),
        http.ClientException('reset'),
      ]);
      final transport = MiddlewareHttpTransport(
        inner,
        retryPolicy: const RetryPolicy(
          maxAttempts: 2,
          baseDelay: Duration(milliseconds: 1),
        ),
      );

      expect(
        () => transport.post(url: 'u', body: 'b', headers: {}),
        throwsA(isA<NetworkException>()),
      );
    });

    test('never retries timeouts and maps them to TimeoutException', () async {
      final inner = _ScriptedTransport([
        async.TimeoutException('slow'),
        const HttpResponse(statusCode: 200, body: 'unused'),
      ]);
      final transport = MiddlewareHttpTransport(
        inner,
        retryPolicy: const RetryPolicy(maxAttempts: 3),
      );

      await expectLater(
        () => transport.post(url: 'u', body: 'b', headers: {}),
        throwsA(isA<TimeoutException>()),
      );
      expect(inner.calls, 1);
    });
  });
}
