enum AuthAction { login, signup }

/// Unified result from auth providers (OTP/OAuth/Passkey).
class AuthResult {
  final String sessionToken;
  final AuthAction? action;
  final String? verificationToken;

  const AuthResult({
    required this.sessionToken,
    this.action,
    this.verificationToken,
  });
}

class OtpInitResult {
  final String otpId;
  final String otpEncryptionTargetBundle;

  const OtpInitResult({
    required this.otpId,
    required this.otpEncryptionTargetBundle,
  });
}

class OtpVerifyResult {
  final String verificationToken;
  final String publicKey;

  const OtpVerifyResult({
    required this.verificationToken,
    required this.publicKey,
  });
}
