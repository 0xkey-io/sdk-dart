import 'package:zeroxkey_http/zeroxkey_http.dart';

import '../domain/repositories/auth_repository.dart';
import '../errors/exceptions.dart';
import 'auth_provider.dart';
import 'auth_result.dart';

/// OAuth auth-proxy orchestration (login/signup via OIDC token).
class OAuthAuthProvider implements AuthProvider {
  final AuthRepository _auth;

  OAuthAuthProvider({required AuthRepository auth}) : _auth = auth;

  @override
  String get name => 'oauth';

  Future<AuthResult> loginWithOAuth({
    required String oidcToken,
    required String publicKey,
    bool invalidateExisting = false,
  }) async {
    try {
      final res = await _auth.oauthLogin(
        body: ProxyTOAuthLoginBody(
          oidcToken: oidcToken,
          publicKey: publicKey,
          invalidateExisting: invalidateExisting,
        ),
      );
      return AuthResult(sessionToken: res.session, action: AuthAction.login);
    } catch (e) {
      if (e is ZeroXKeyException) rethrow;
      throw AuthException('OAuth login failed: $e');
    }
  }

  Future<AuthResult> signUpWithOAuth({
    required ProxyTSignupV2Body signUpBody,
    required String oidcToken,
    required String publicKey,
    bool invalidateExisting = false,
  }) async {
    try {
      final res = await _auth.signup(body: signUpBody);
      if (res.organizationId.isEmpty) {
        throw const AuthException('Sign up failed: no organizationId returned');
      }
      return loginWithOAuth(
        oidcToken: oidcToken,
        publicKey: publicKey,
        invalidateExisting: invalidateExisting,
      );
    } catch (e) {
      if (e is ZeroXKeyException) rethrow;
      throw AuthException('Sign up failed: $e');
    }
  }

  Future<AuthResult> loginOrSignUpWithOAuth({
    required String oidcToken,
    required String publicKey,
    String? providerName,
    bool invalidateExisting = false,
    Future<AuthResult> Function()? onSignup,
  }) async {
    final account = await _auth.getAccount(
      body: ProxyTGetAccountBody(
        filterType: 'OIDC_TOKEN',
        filterValue: oidcToken,
      ),
    );
    if (account.organizationId?.isNotEmpty == true) {
      return loginWithOAuth(
        oidcToken: oidcToken,
        publicKey: publicKey,
        invalidateExisting: invalidateExisting,
      );
    }
    if (providerName == null || providerName.isEmpty) {
      throw const AuthException('Provider name is required for OAuth signup');
    }
    if (onSignup == null) {
      throw const AuthException(
          'Signup handler required for new OAuth account');
    }
    final signup = await onSignup();
    return AuthResult(
      sessionToken: signup.sessionToken,
      action: AuthAction.signup,
    );
  }
}
