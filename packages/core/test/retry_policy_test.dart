import 'dart:math';

import 'package:test/test.dart';
import 'package:zeroxkey_core/zeroxkey_core.dart';

void main() {
  group('RetryPolicy', () {
    test('shouldRetry respects maxAttempts', () {
      const policy = RetryPolicy(maxAttempts: 3);
      expect(policy.shouldRetry(1), isTrue);
      expect(policy.shouldRetry(2), isTrue);
      expect(policy.shouldRetry(3), isFalse);
    });

    test('none disables retries', () {
      expect(RetryPolicy.none.shouldRetry(1), isFalse);
    });

    test('delay grows exponentially and is capped at maxDelay', () {
      const policy = RetryPolicy(
        baseDelay: Duration(milliseconds: 100),
        maxDelay: Duration(milliseconds: 400),
        jitterFactor: 0,
      );
      final zeroJitter = Random(1);
      expect(policy.delayForAttempt(1, random: zeroJitter).inMilliseconds, 100);
      expect(policy.delayForAttempt(2, random: zeroJitter).inMilliseconds, 200);
      expect(policy.delayForAttempt(3, random: zeroJitter).inMilliseconds, 400);
      // capped
      expect(
          policy.delayForAttempt(10, random: zeroJitter).inMilliseconds, 400);
    });
  });
}
