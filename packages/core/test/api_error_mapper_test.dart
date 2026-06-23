import 'dart:async' as async;

import 'package:test/test.dart';
import 'package:zeroxkey_core/zeroxkey_core.dart';
import 'package:zeroxkey_http/zeroxkey_http.dart'
    show GrpcStatus, ZeroXKeyRequestError;

void main() {
  group('ApiErrorMapper', () {
    const mapper = ApiErrorMapper();

    test('maps ZeroXKeyRequestError to ApiException preserving code/message',
        () {
      final error = ZeroXKeyRequestError(
        GrpcStatus(message: 'not found', code: 5, details: const ['d']),
      );

      expect(
        () => mapper.map(error),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 5)
              .having((e) => e.message, 'message', contains('not found'))
              .having((e) => e.details, 'details', equals(['d'])),
        ),
      );
    });

    test('rethrows an already-mapped ZeroXKeyException unchanged', () {
      const original = SigningException('boom');
      expect(() => mapper.map(original), throwsA(same(original)));
    });

    test('maps dart TimeoutException to core TimeoutException', () {
      expect(
        () => mapper.map(async.TimeoutException('slow')),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('wraps unknown errors as NetworkException', () {
      expect(
        () => mapper.map(StateError('weird')),
        throwsA(isA<NetworkException>()),
      );
    });

    test('guard surfaces mapped exceptions', () {
      expect(
        () => mapper.guard(() async =>
            throw ZeroXKeyRequestError(GrpcStatus(message: 'x', code: 2))),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
