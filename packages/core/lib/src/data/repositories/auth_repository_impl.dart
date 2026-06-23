import 'package:zeroxkey_http/zeroxkey_http.dart';

import '../../network/api_error_mapper.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ZeroXKeyClient Function() _client;
  final ApiErrorMapper _errors;

  AuthRepositoryImpl(
    this._client, {
    ApiErrorMapper errors = const ApiErrorMapper(),
  }) : _errors = errors;

  @override
  Future<ProxyTInitOtpV2Response> initOtp({
    required String contact,
    required String otpType,
  }) {
    return _errors.guard(() => _client().proxyInitOtpV2(
          input: ProxyTInitOtpV2Body(contact: contact, otpType: otpType),
        ));
  }

  @override
  Future<ProxyTVerifyOtpV2Response> verifyOtp({
    required String otpId,
    required String encryptedOtpBundle,
  }) {
    return _errors.guard(() => _client().proxyVerifyOtpV2(
          input: ProxyTVerifyOtpV2Body(
            otpId: otpId,
            encryptedOtpBundle: encryptedOtpBundle,
          ),
        ));
  }

  @override
  Future<ProxyTOtpLoginV2Response> otpLogin({
    required ProxyTOtpLoginV2Body body,
  }) {
    return _errors.guard(() => _client().proxyOtpLoginV2(input: body));
  }

  @override
  Future<ProxyTSignupV2Response> signup({required ProxyTSignupV2Body body}) {
    return _errors.guard(() => _client().proxySignupV2(input: body));
  }

  @override
  Future<ProxyTGetAccountResponse> getAccount({
    required ProxyTGetAccountBody body,
  }) {
    return _errors.guard(() => _client().proxyGetAccount(input: body));
  }

  @override
  Future<ProxyTOAuthLoginResponse> oauthLogin({
    required ProxyTOAuthLoginBody body,
  }) {
    return _errors.guard(() => _client().proxyOAuthLogin(input: body));
  }
}
