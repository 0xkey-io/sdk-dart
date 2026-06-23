import '../network/retry_policy.dart';
import '../provider/backend_provider.dart';

/// Tunables for the network stack, consumed by `MiddlewareHttpTransport`.
class NetworkOptions {
  final Duration timeout;
  final RetryPolicy retryPolicy;

  const NetworkOptions({
    this.timeout = const Duration(seconds: 30),
    this.retryPolicy = const RetryPolicy(),
  });
}

/// Immutable, platform-agnostic configuration consumed by the core composition
/// root. Presentation-layer config (Flutter-facing `ZeroXKeyConfig`, OAuth
/// provider params, session callbacks) is mapped into this decoupled value
/// object so the core never depends on UI concerns.
class ZeroXKeyConfiguration {
  final BackendProvider backend;
  final NetworkOptions network;

  /// Default session lifetime (seconds, as a string to match the wire field).
  final String sessionExpirationSeconds;

  const ZeroXKeyConfiguration({
    required this.backend,
    this.network = const NetworkOptions(),
    this.sessionExpirationSeconds = '900',
  });
}
