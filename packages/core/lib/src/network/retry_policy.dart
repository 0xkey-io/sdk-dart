import 'dart:math';

/// Exponential-backoff retry policy for transport-level failures.
///
/// Only failures that provably occurred before the request reached the server
/// (connection errors) are safe to retry blindly; this policy is therefore
/// applied exclusively to network establishment errors by
/// `MiddlewareHttpTransport` — never to timeouts (indeterminate) or to non-200
/// responses (already delivered).
class RetryPolicy {
  /// Total attempts including the first try. `1` disables retries.
  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;
  final double jitterFactor;

  const RetryPolicy({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(milliseconds: 200),
    this.maxDelay = const Duration(seconds: 2),
    this.jitterFactor = 0.2,
  })  : assert(maxAttempts >= 1, 'maxAttempts must be >= 1'),
        assert(jitterFactor >= 0 && jitterFactor <= 1,
            'jitterFactor must be within [0, 1]');

  /// Disabled policy (single attempt, no retries).
  static const RetryPolicy none = RetryPolicy(maxAttempts: 1);

  bool shouldRetry(int attempt) => attempt < maxAttempts;

  /// Backoff before the next attempt (1-indexed: [attempt] 1 is after the first
  /// failure). Applies full exponential growth capped at [maxDelay] plus jitter.
  Duration delayForAttempt(int attempt, {Random? random}) {
    final rng = random ?? _random;
    final exp = baseDelay.inMilliseconds * pow(2, attempt - 1);
    final capped = min(exp.toDouble(), maxDelay.inMilliseconds.toDouble());
    final jitter = capped * jitterFactor * rng.nextDouble();
    return Duration(milliseconds: (capped + jitter).round());
  }

  static final Random _random = Random();
}
