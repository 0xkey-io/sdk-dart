import '../../auth/auth_result.dart';
import '../../auth/otp_auth_provider.dart';

class InitOtpUseCase {
  final OtpAuthProvider _otp;

  InitOtpUseCase(this._otp);

  Future<OtpInitResult> call({
    required String contact,
    required String otpType,
  }) {
    return _otp.initOtp(contact: contact, otpType: otpType);
  }
}

class VerifyOtpUseCase {
  final OtpAuthProvider _otp;

  VerifyOtpUseCase(this._otp);

  Future<OtpVerifyResult> call({
    required String otpId,
    required String otpCode,
    required String otpEncryptionTargetBundle,
    String? publicKey,
  }) {
    return _otp.verifyOtp(
      otpId: otpId,
      otpCode: otpCode,
      otpEncryptionTargetBundle: otpEncryptionTargetBundle,
      publicKey: publicKey,
    );
  }
}

class LoginWithOtpUseCase {
  final OtpAuthProvider _otp;

  LoginWithOtpUseCase(this._otp);

  Future<AuthResult> call({
    required String verificationToken,
    String? organizationId,
    bool invalidateExisting = false,
  }) {
    return _otp.loginWithOtp(
      verificationToken: verificationToken,
      organizationId: organizationId,
      invalidateExisting: invalidateExisting,
    );
  }
}
