import 'package:zeroxkey_http/zeroxkey_http.dart';

import '../../auth/auth_result.dart';
import '../../auth/otp_auth_provider.dart';

class SignUpWithOtpUseCase {
  final OtpAuthProvider _otp;

  SignUpWithOtpUseCase(this._otp);

  Future<AuthResult> call({
    required String verificationToken,
    required ProxyTSignupV2Body signUpBody,
    bool invalidateExisting = false,
  }) {
    return _otp.signUpWithOtp(
      verificationToken: verificationToken,
      signUpBody: signUpBody,
      invalidateExisting: invalidateExisting,
    );
  }
}

class LoginOrSignUpWithOtpUseCase {
  final OtpAuthProvider _otp;

  LoginOrSignUpWithOtpUseCase(this._otp);

  Future<AuthResult> call({
    required String otpId,
    required String otpCode,
    required String otpEncryptionTargetBundle,
    required String contact,
    required String otpFilterType,
    String? publicKey,
    bool invalidateExisting = false,
    required Future<AuthResult> Function(OtpVerifyResult verify) onSignup,
  }) {
    return _otp.loginOrSignUpWithOtp(
      otpId: otpId,
      otpCode: otpCode,
      otpEncryptionTargetBundle: otpEncryptionTargetBundle,
      contact: contact,
      otpFilterType: otpFilterType,
      publicKey: publicKey,
      invalidateExisting: invalidateExisting,
      onSignup: onSignup,
    );
  }
}
