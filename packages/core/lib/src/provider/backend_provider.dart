/// Describes a custody backend the SDK can talk to.
///
/// This is the seam that keeps the SDK protocol-compatible while remaining open
/// to additional custody providers (Strategy/Adapter). It carries only the
/// values that differ between deployments — base URLs, organization/proxy
/// routing, the HPKE info string, and an optional enclave signer override. It
/// deliberately does NOT carry per-request bundle material (e.g. HPKE
/// `targetPublic`), which always originates from signed API responses.
abstract class BackendProvider {
  /// Base URL of the main (stamped) API.
  String get apiBaseUrl;

  /// Base URL of the auth proxy used by OTP/OAuth bootstrap flows.
  String get authProxyBaseUrl;

  /// Auth proxy configuration id (required for proxy routes).
  String? get authProxyConfigId;

  /// Default organization id for activity envelopes.
  String? get organizationId;

  /// HPKE info string used to isolate this provider's encryption schedule.
  String get hpkeInfo;

  /// Optional override for the enclave signer public key used to verify import/
  /// export bundles. `null` defers to the crypto package's production constants,
  /// preserving current behavior exactly.
  String? get signerPublicKeyOverride;
}

/// Default [BackendProvider] for the ZeroXKey production deployment.
///
/// All defaults reproduce the pre-refactor behavior: `api.0xkey.io`,
/// `authproxy.0xkey.io`, the `0xkey_hpke` info string, and no signer override.
class ZeroXKeyBackendProvider implements BackendProvider {
  @override
  final String apiBaseUrl;
  @override
  final String authProxyBaseUrl;
  @override
  final String? authProxyConfigId;
  @override
  final String? organizationId;
  @override
  final String hpkeInfo;
  @override
  final String? signerPublicKeyOverride;

  const ZeroXKeyBackendProvider({
    this.apiBaseUrl = 'https://api.0xkey.io',
    this.authProxyBaseUrl = 'https://authproxy.0xkey.io',
    this.authProxyConfigId,
    this.organizationId,
    this.hpkeInfo = '0xkey_hpke',
    this.signerPublicKeyOverride,
  });

  ZeroXKeyBackendProvider copyWith({
    String? apiBaseUrl,
    String? authProxyBaseUrl,
    String? authProxyConfigId,
    String? organizationId,
    String? hpkeInfo,
    String? signerPublicKeyOverride,
  }) {
    return ZeroXKeyBackendProvider(
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      authProxyBaseUrl: authProxyBaseUrl ?? this.authProxyBaseUrl,
      authProxyConfigId: authProxyConfigId ?? this.authProxyConfigId,
      organizationId: organizationId ?? this.organizationId,
      hpkeInfo: hpkeInfo ?? this.hpkeInfo,
      signerPublicKeyOverride:
          signerPublicKeyOverride ?? this.signerPublicKeyOverride,
    );
  }
}
