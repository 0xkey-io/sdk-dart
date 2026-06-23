part of 'zeroxkey.dart';

extension AuthProxyExtension on ZeroXKeyProvider {
  /// Initializes the OTP process by sending an OTP code to the provided contact.
  Future<InitOtpResult> initOtp(
      {required OtpType otpType, required String contact}) async {
    final res = await _container.initOtpUseCase.call(
      contact: contact,
      otpType: otpType.value,
    );
    return InitOtpResult(
      otpId: res.otpId,
      otpEncryptionTargetBundle: res.otpEncryptionTargetBundle,
    );
  }

  /// Verifies the OTP code sent to the user.
  Future<VerifyOtpResult> verifyOtp({
    required String otpId,
    required String otpCode,
    required String otpEncryptionTargetBundle,
    String? publicKey,
  }) async {
    final res = await _container.verifyOtpUseCase.call(
      otpId: otpId,
      otpCode: otpCode,
      otpEncryptionTargetBundle: otpEncryptionTargetBundle,
      publicKey: publicKey,
    );
    return VerifyOtpResult(
      verificationToken: res.verificationToken,
      publicKey: res.publicKey,
    );
  }

  /// Logs in a user using an OTP verification token.
  Future<LoginWithOtpResult> loginWithOtp({
    required String verificationToken,
    String? organizationId,
    bool invalidateExisting = false,
    String? sessionKey,
  }) async {
    try {
      final res = await _container.loginWithOtpUseCase.call(
        verificationToken: verificationToken,
        organizationId: organizationId,
        invalidateExisting: invalidateExisting,
      );
      await storeSession(sessionJwt: res.sessionToken, sessionKey: sessionKey);
      return LoginWithOtpResult(sessionToken: res.sessionToken);
    } catch (error) {
      await deleteUnusedKeyPairs();
      throw Exception('Failed to login with otp: $error');
    }
  }

  /// Signs up a user using an OTP verification token.
  Future<SignUpWithOtpResult> signUpWithOtp({
    required String verificationToken,
    required String contact,
    required OtpType otpType,
    String? sessionKey,
    CreateSubOrgParams? createSubOrgParams,
    bool invalidateExisting = false,
  }) async {
    final overrideParams = OtpOverriredParams(
      otpType: otpType,
      contact: contact,
      verificationToken: verificationToken,
    );
    final updatedCreateSubOrgParams =
        getCreateSubOrgParams(createSubOrgParams, config, overrideParams);
    final signUpBody =
        buildSignUpBody(createSubOrgParams: updatedCreateSubOrgParams);

    try {
      final res = await _container.signUpWithOtpUseCase.call(
        verificationToken: verificationToken,
        signUpBody: signUpBody,
        invalidateExisting: invalidateExisting,
      );
      await storeSession(sessionJwt: res.sessionToken, sessionKey: sessionKey);
      return SignUpWithOtpResult(sessionToken: res.sessionToken);
    } catch (e) {
      await deleteUnusedKeyPairs();
      throw Exception('Sign up failed: $e');
    }
  }

  /// Completes the OTP authentication flow (login or signup).
  Future<LoginOrSignUpWithOtpResult> loginOrSignUpWithOtp({
    required String otpId,
    required String otpCode,
    required String otpEncryptionTargetBundle,
    required String contact,
    required OtpType otpType,
    String? publicKey,
    bool invalidateExisting = false,
    String? sessionKey,
    CreateSubOrgParams? createSubOrgParams,
  }) async {
    try {
      final res = await _container.loginOrSignUpWithOtpUseCase.call(
        otpId: otpId,
        otpCode: otpCode,
        otpEncryptionTargetBundle: otpEncryptionTargetBundle,
        contact: contact,
        otpFilterType: otpTypeToFilterTypeMap[otpType]!.value,
        publicKey: publicKey,
        invalidateExisting: invalidateExisting,
        onSignup: (verify) async {
          final signUp = await signUpWithOtp(
            verificationToken: verify.verificationToken,
            contact: contact,
            otpType: otpType,
            createSubOrgParams: createSubOrgParams,
            invalidateExisting: invalidateExisting,
            sessionKey: sessionKey,
          );
          return AuthResult(sessionToken: signUp.sessionToken);
        },
      );

      if (res.action?.name == 'login') {
        await storeSession(
            sessionJwt: res.sessionToken, sessionKey: sessionKey);
      }

      return LoginOrSignUpWithOtpResult(
        sessionToken: res.sessionToken,
        verificationToken: res.verificationToken ?? '',
        action:
            res.action?.name == 'signup' ? AuthAction.signup : AuthAction.login,
      );
    } catch (e) {
      await deleteUnusedKeyPairs();
      throw Exception('OTP authentication failed: $e');
    }
  }

  /// Logs in a user using an OAuth token.
  Future<LoginWithOAuthResult> loginWithOAuth({
    required String oidcToken,
    required String publicKey,
    bool? invalidateExisting = false,
    String? sessionKey,
  }) async {
    try {
      final res = await _container.loginWithOAuthUseCase.call(
        oidcToken: oidcToken,
        publicKey: publicKey,
        invalidateExisting: invalidateExisting ?? false,
      );
      await storeSession(sessionJwt: res.sessionToken, sessionKey: sessionKey);
      return LoginWithOAuthResult(sessionToken: res.sessionToken);
    } catch (e) {
      throw Exception('OAuth login failed: $e');
    }
  }

  /// Signs up a new user using an OAuth token.
  Future<SignUpWithOAuthResult> signUpWithOAuth({
    required String oidcToken,
    required String publicKey,
    required String providerName,
    String? sessionKey,
    CreateSubOrgParams? createSubOrgParams,
  }) async {
    final overrideParams = OAuthOverridedParams(
      oidcToken: oidcToken,
      providerName: providerName,
    );
    final updatedCreateSubOrgParams =
        getCreateSubOrgParams(createSubOrgParams, config, overrideParams);
    final signUpBody =
        buildSignUpBody(createSubOrgParams: updatedCreateSubOrgParams);

    try {
      final res = await _container.authRepository.signup(body: signUpBody);
      if (res.organizationId.isEmpty) {
        throw Exception('Sign up failed: No organizationId returned');
      }
      final login = await loginWithOAuth(
        oidcToken: oidcToken,
        publicKey: publicKey,
        sessionKey: sessionKey,
      );
      return SignUpWithOAuthResult(sessionToken: login.sessionToken);
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  /// Completes the OAuth authentication process.
  Future<LoginOrSignUpWithOAuthResult> loginOrSignUpWithOAuth({
    required String oidcToken,
    required String publicKey,
    String? providerName,
    String? sessionKey,
    bool? invalidateExisting,
    CreateSubOrgParams? createSubOrgParams,
  }) async {
    try {
      final res = await _container.loginOrSignUpWithOAuthUseCase.call(
        oidcToken: oidcToken,
        publicKey: publicKey,
        providerName: providerName,
        invalidateExisting: invalidateExisting ?? false,
        onSignup: () async {
          if (providerName == null || providerName.isEmpty) {
            throw Exception('Provider name is required for sign up');
          }
          final signUp = await signUpWithOAuth(
            oidcToken: oidcToken,
            publicKey: publicKey,
            providerName: providerName,
            sessionKey: sessionKey,
            createSubOrgParams: createSubOrgParams,
          );
          return AuthResult(sessionToken: signUp.sessionToken);
        },
      );

      if (res.action?.name == 'login') {
        await storeSession(
            sessionJwt: res.sessionToken, sessionKey: sessionKey);
      }

      return LoginOrSignUpWithOAuthResult(
        sessionToken: res.sessionToken,
        action:
            res.action?.name == 'signup' ? AuthAction.signup : AuthAction.login,
      );
    } catch (e) {
      throw Exception('OAuth authentication failed: $e');
    }
  }
}
