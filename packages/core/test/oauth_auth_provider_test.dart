import 'package:test/test.dart';
import 'package:zeroxkey_core/zeroxkey_core.dart';
import 'package:zeroxkey_http/zeroxkey_http.dart';

/// Configurable fake of [AuthRepository] for OAuth orchestration tests.
class _FakeAuthRepository implements AuthRepository {
  String? accountOrganizationId;
  String oauthSession = 'oauth-session';
  ProxyTGetAccountBody? lastGetAccount;
  ProxyTOAuthLoginBody? lastOAuthLogin;

  @override
  Future<ProxyTGetAccountResponse> getAccount({
    required ProxyTGetAccountBody body,
  }) async {
    lastGetAccount = body;
    return ProxyTGetAccountResponse(organizationId: accountOrganizationId);
  }

  @override
  Future<ProxyTOAuthLoginResponse> oauthLogin({
    required ProxyTOAuthLoginBody body,
  }) async {
    lastOAuthLogin = body;
    return ProxyTOAuthLoginResponse(session: oauthSession);
  }

  @override
  Future<ProxyTInitOtpV2Response> initOtp({
    required String contact,
    required String otpType,
  }) =>
      throw UnimplementedError();

  @override
  Future<ProxyTVerifyOtpV2Response> verifyOtp({
    required String otpId,
    required String encryptedOtpBundle,
  }) =>
      throw UnimplementedError();

  @override
  Future<ProxyTOtpLoginV2Response> otpLogin({
    required ProxyTOtpLoginV2Body body,
  }) =>
      throw UnimplementedError();

  @override
  Future<ProxyTSignupV2Response> signup({required ProxyTSignupV2Body body}) =>
      throw UnimplementedError();
}

void main() {
  group('OAuthAuthProvider.loginWithOAuth', () {
    test('returns a login AuthResult with the session token', () async {
      final auth = _FakeAuthRepository()..oauthSession = 'sess-1';
      final provider = OAuthAuthProvider(auth: auth);

      final result = await provider.loginWithOAuth(
        oidcToken: 'oidc',
        publicKey: 'pk',
      );

      expect(result.sessionToken, 'sess-1');
      expect(result.action, AuthAction.login);
      expect(auth.lastOAuthLogin?.oidcToken, 'oidc');
      expect(auth.lastOAuthLogin?.publicKey, 'pk');
    });
  });

  group('OAuthAuthProvider.loginOrSignUpWithOAuth', () {
    test('logs in when the account already exists', () async {
      final auth = _FakeAuthRepository()
        ..accountOrganizationId = 'org-123'
        ..oauthSession = 'login-sess';
      final provider = OAuthAuthProvider(auth: auth);

      final result = await provider.loginOrSignUpWithOAuth(
        oidcToken: 'oidc',
        publicKey: 'pk',
      );

      expect(result.action, AuthAction.login);
      expect(result.sessionToken, 'login-sess');
      expect(auth.lastGetAccount?.filterType, 'OIDC_TOKEN');
    });

    test('signs up via the onSignup handler for a new account', () async {
      final auth = _FakeAuthRepository()..accountOrganizationId = null;
      final provider = OAuthAuthProvider(auth: auth);
      var signupCalled = false;

      final result = await provider.loginOrSignUpWithOAuth(
        oidcToken: 'oidc',
        publicKey: 'pk',
        providerName: 'google',
        onSignup: () async {
          signupCalled = true;
          return const AuthResult(sessionToken: 'signup-sess');
        },
      );

      expect(signupCalled, isTrue);
      expect(result.action, AuthAction.signup);
      expect(result.sessionToken, 'signup-sess');
    });

    test('throws when a new account has no provider name', () async {
      final auth = _FakeAuthRepository()..accountOrganizationId = null;
      final provider = OAuthAuthProvider(auth: auth);

      expect(
        () => provider.loginOrSignUpWithOAuth(
          oidcToken: 'oidc',
          publicKey: 'pk',
          onSignup: () async => const AuthResult(sessionToken: 'x'),
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
