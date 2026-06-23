/// Flutter/browser-specific OAuth redirect surface. Core auth providers depend
/// on this port; sdk-flutter implements it with inappwebview / app_links /
/// sign_in_with_apple.
abstract class OAuthRedirectHandler {
  /// Returns an OIDC token after completing the provider-specific redirect flow.
  Future<String> fetchOidcToken({
    required String providerName,
    required String primaryClientId,
    List<String>? secondaryClientIds,
    String? originUri,
    String? redirectUri,
  });
}
