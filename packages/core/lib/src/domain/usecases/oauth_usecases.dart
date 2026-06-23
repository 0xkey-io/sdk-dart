import '../../auth/auth_result.dart';
import '../../auth/oauth_auth_provider.dart';

class LoginWithOAuthUseCase {
  final OAuthAuthProvider _oauth;

  LoginWithOAuthUseCase(this._oauth);

  Future<AuthResult> call({
    required String oidcToken,
    required String publicKey,
    bool invalidateExisting = false,
  }) {
    return _oauth.loginWithOAuth(
      oidcToken: oidcToken,
      publicKey: publicKey,
      invalidateExisting: invalidateExisting,
    );
  }
}

class LoginOrSignUpWithOAuthUseCase {
  final OAuthAuthProvider _oauth;

  LoginOrSignUpWithOAuthUseCase(this._oauth);

  Future<AuthResult> call({
    required String oidcToken,
    required String publicKey,
    String? providerName,
    bool invalidateExisting = false,
    Future<AuthResult> Function()? onSignup,
  }) {
    return _oauth.loginOrSignUpWithOAuth(
      oidcToken: oidcToken,
      publicKey: publicKey,
      providerName: providerName,
      invalidateExisting: invalidateExisting,
      onSignup: onSignup,
    );
  }
}
