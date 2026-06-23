import 'package:zeroxkey_http/zeroxkey_http.dart'
    show ProxyTGetWalletKitConfigResponse;

import 'configuration.dart';

/// Fully-resolved runtime settings after optional auth-proxy wallet-kit fetch.
///
/// Mirrors the presentation layer's `_buildConfig` output without importing
/// Flutter-facing OAuth types.
class ResolvedRuntimeConfig {
  final String apiBaseUrl;
  final String authProxyBaseUrl;
  final String? authProxyConfigId;
  final String? organizationId;
  final String sessionExpirationSeconds;
  final ProxyTGetWalletKitConfigResponse? walletKitConfig;

  const ResolvedRuntimeConfig({
    required this.apiBaseUrl,
    required this.authProxyBaseUrl,
    this.authProxyConfigId,
    this.organizationId,
    this.sessionExpirationSeconds = '900',
    this.walletKitConfig,
  });

  factory ResolvedRuntimeConfig.fromCore(
    ZeroXKeyConfiguration configuration, {
    ProxyTGetWalletKitConfigResponse? walletKitConfig,
  }) {
    final backend = configuration.backend;
    return ResolvedRuntimeConfig(
      apiBaseUrl: backend.apiBaseUrl,
      authProxyBaseUrl: backend.authProxyBaseUrl,
      authProxyConfigId: backend.authProxyConfigId,
      organizationId: backend.organizationId,
      sessionExpirationSeconds: configuration.sessionExpirationSeconds,
      walletKitConfig: walletKitConfig,
    );
  }
}
