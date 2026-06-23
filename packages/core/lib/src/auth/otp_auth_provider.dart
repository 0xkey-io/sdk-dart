import 'package:zeroxkey_crypto/zeroxkey_crypto.dart'
    show encryptOtpCodeToBundle;
import 'package:zeroxkey_http/zeroxkey_http.dart';

import '../data/client_signature_codec.dart';
import '../domain/repositories/auth_repository.dart';
import '../errors/exceptions.dart';
import '../signing/signer.dart';
import 'auth_provider.dart';
import 'auth_result.dart';

/// OTP auth-proxy orchestration (init → verify → login/signup).
class OtpAuthProvider implements AuthProvider {
  final AuthRepository _auth;
  final Signer _signer;
  final KeyStore _keyStore;
  final ClientSignatureCodec _signatures;

  OtpAuthProvider({
    required AuthRepository auth,
    required Signer signer,
    required KeyStore keyStore,
    ClientSignatureCodec signatures = const ClientSignatureCodec(),
  })  : _auth = auth,
        _signer = signer,
        _keyStore = keyStore,
        _signatures = signatures;

  @override
  String get name => 'otp';

  Future<OtpInitResult> initOtp({
    required String contact,
    required String otpType,
  }) async {
    final res = await _auth.initOtp(contact: contact, otpType: otpType);
    if (res.otpId.isEmpty || res.otpEncryptionTargetBundle.isEmpty) {
      throw const AuthException(
        'Failed to initialize OTP: missing otpId or encryption bundle',
      );
    }
    return OtpInitResult(
      otpId: res.otpId,
      otpEncryptionTargetBundle: res.otpEncryptionTargetBundle,
    );
  }

  Future<OtpVerifyResult> verifyOtp({
    required String otpId,
    required String otpCode,
    required String otpEncryptionTargetBundle,
    String? publicKey,
  }) async {
    final resolvedPublicKey =
        publicKey ?? await _keyStore.createKeyPair(isCompressed: true);
    try {
      final encryptedOtpBundle = await encryptOtpCodeToBundle(
        otpCode: otpCode,
        otpEncryptionTargetBundle: otpEncryptionTargetBundle,
        publicKey: resolvedPublicKey,
      );
      final res = await _auth.verifyOtp(
        otpId: otpId,
        encryptedOtpBundle: encryptedOtpBundle,
      );
      if (res.verificationToken.isEmpty) {
        throw const AuthException('OTP verification failed');
      }
      return OtpVerifyResult(
        verificationToken: res.verificationToken,
        publicKey: resolvedPublicKey,
      );
    } catch (e) {
      await _deleteUnusedKeys();
      if (e is ZeroXKeyException) rethrow;
      throw AuthException('OTP verification failed: $e');
    }
  }

  Future<AuthResult> loginWithOtp({
    required String verificationToken,
    String? organizationId,
    bool invalidateExisting = false,
  }) async {
    try {
      final payload =
          _signatures.forLogin(verificationToken: verificationToken);
      _signer.setPublicKey(payload.clientSignaturePublicKey);
      final signature = await _signer.sign(
        payload.message,
        format: SignatureFormat.raw,
      );
      if (signature.isEmpty) {
        throw const AuthException(
            'Failed to create client signature on OTP login');
      }
      final clientSignature = v1ClientSignature(
        message: payload.message,
        publicKey: payload.clientSignaturePublicKey,
        scheme: v1ClientSignatureScheme.client_signature_scheme_api_p256,
        signature: signature,
      );
      final res = await _auth.otpLogin(
        body: ProxyTOtpLoginV2Body(
          verificationToken: verificationToken,
          publicKey: payload.clientSignaturePublicKey,
          clientSignature: clientSignature,
          invalidateExisting: invalidateExisting,
          organizationId: organizationId,
        ),
      );
      if (res.session.isEmpty) {
        throw const AuthException('No session returned from OTP login');
      }
      return AuthResult(sessionToken: res.session, action: AuthAction.login);
    } catch (e) {
      await _deleteUnusedKeys();
      if (e is ZeroXKeyException) rethrow;
      throw AuthException('Failed to login with OTP: $e');
    }
  }

  Future<AuthResult> loginOrSignUpWithOtp({
    required String otpId,
    required String otpCode,
    required String otpEncryptionTargetBundle,
    required String contact,
    required String otpFilterType,
    String? publicKey,
    bool invalidateExisting = false,
    Future<AuthResult> Function(OtpVerifyResult verify)? onSignup,
  }) async {
    final verify = await verifyOtp(
      otpId: otpId,
      otpCode: otpCode,
      otpEncryptionTargetBundle: otpEncryptionTargetBundle,
      publicKey: publicKey,
    );
    final account = await _auth.getAccount(
      body: ProxyTGetAccountBody(
        filterType: otpFilterType,
        filterValue: contact,
        verificationToken: verify.verificationToken,
      ),
    );
    final orgId = account.organizationId;
    if (orgId == null || orgId.isEmpty) {
      if (onSignup == null) {
        throw const AuthException('Signup handler required for new account');
      }
      final signup = await onSignup(verify);
      return AuthResult(
        sessionToken: signup.sessionToken,
        verificationToken: verify.verificationToken,
        action: AuthAction.signup,
      );
    }
    final login = await loginWithOtp(
      verificationToken: verify.verificationToken,
      invalidateExisting: invalidateExisting,
    );
    return AuthResult(
      sessionToken: login.sessionToken,
      verificationToken: verify.verificationToken,
      action: AuthAction.login,
    );
  }

  Future<AuthResult> signUpWithOtp({
    required String verificationToken,
    required ProxyTSignupV2Body signUpBody,
    bool invalidateExisting = false,
  }) async {
    try {
      final payload = _signatures.forSignup(
        verificationToken: verificationToken,
        email: signUpBody.userEmail,
        phoneNumber: signUpBody.userPhoneNumber,
        apiKeys: signUpBody.apiKeys,
        authenticators: signUpBody.authenticators,
        oauthProviders: signUpBody.oauthProviders,
      );
      _signer.setPublicKey(payload.clientSignaturePublicKey);
      final signature = await _signer.sign(
        payload.message,
        format: SignatureFormat.raw,
      );
      if (signature.isEmpty) {
        throw const AuthException(
            'Failed to create client signature on OTP signup');
      }
      final clientSignature = v1ClientSignature(
        message: payload.message,
        publicKey: payload.clientSignaturePublicKey,
        scheme: v1ClientSignatureScheme.client_signature_scheme_api_p256,
        signature: signature,
      );
      final signUpBodyWithSignature = ProxyTSignupV2Body(
        userEmail: signUpBody.userEmail,
        userPhoneNumber: signUpBody.userPhoneNumber,
        userTag: signUpBody.userTag,
        userName: signUpBody.userName,
        organizationName: signUpBody.organizationName,
        verificationToken: signUpBody.verificationToken,
        apiKeys: signUpBody.apiKeys,
        authenticators: signUpBody.authenticators,
        oauthProviders: signUpBody.oauthProviders,
        wallet: signUpBody.wallet,
        clientSignature: clientSignature,
      );
      final signupRes = await _auth.signup(body: signUpBodyWithSignature);
      if (signupRes.organizationId.isEmpty) {
        throw const AuthException('Auth proxy OTP sign up failed');
      }
      return loginWithOtp(
        verificationToken: verificationToken,
        invalidateExisting: invalidateExisting,
      );
    } catch (e) {
      await _deleteUnusedKeys();
      if (e is ZeroXKeyException) rethrow;
      throw AuthException('Sign up failed: $e');
    }
  }

  Future<void> _deleteUnusedKeys() async {
    final keys = await _keyStore.listKeyPairs();
    for (final key in keys) {
      await _keyStore.deleteKeyPair(key);
    }
  }
}
