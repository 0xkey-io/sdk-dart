import 'package:zeroxkey_http/zeroxkey_http.dart';

/// Auth-proxy (OTP/OAuth) wire operations.
abstract class AuthRepository {
  Future<ProxyTInitOtpV2Response> initOtp({
    required String contact,
    required String otpType,
  });

  Future<ProxyTVerifyOtpV2Response> verifyOtp({
    required String otpId,
    required String encryptedOtpBundle,
  });

  Future<ProxyTOtpLoginV2Response> otpLogin({
    required ProxyTOtpLoginV2Body body,
  });

  Future<ProxyTSignupV2Response> signup({
    required ProxyTSignupV2Body body,
  });

  Future<ProxyTGetAccountResponse> getAccount({
    required ProxyTGetAccountBody body,
  });

  Future<ProxyTOAuthLoginResponse> oauthLogin({
    required ProxyTOAuthLoginBody body,
  });
}
