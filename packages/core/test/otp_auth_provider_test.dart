import 'package:test/test.dart';
import 'package:zeroxkey_core/zeroxkey_core.dart';
import 'package:zeroxkey_http/zeroxkey_http.dart';

class _FakeAuthRepository implements AuthRepository {
  ProxyTInitOtpV2Response initResponse = ProxyTInitOtpV2Response(
    otpId: 'otp-1',
    otpEncryptionTargetBundle: 'bundle-1',
  );

  @override
  Future<ProxyTInitOtpV2Response> initOtp({
    required String contact,
    required String otpType,
  }) async {
    return initResponse;
  }

  @override
  Future<ProxyTVerifyOtpV2Response> verifyOtp({
    required String otpId,
    required String encryptedOtpBundle,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ProxyTOtpLoginV2Response> otpLogin({
    required ProxyTOtpLoginV2Body body,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ProxyTSignupV2Response> signup({required ProxyTSignupV2Body body}) {
    throw UnimplementedError();
  }

  @override
  Future<ProxyTGetAccountResponse> getAccount({
    required ProxyTGetAccountBody body,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ProxyTOAuthLoginResponse> oauthLogin({
    required ProxyTOAuthLoginBody body,
  }) {
    throw UnimplementedError();
  }
}

class _FakeSigner implements Signer {
  String? publicKey;

  @override
  void setPublicKey(String publicKey) => this.publicKey = publicKey;

  @override
  Future<String> sign(String message,
      {SignatureFormat format = SignatureFormat.raw}) {
    throw UnimplementedError();
  }

  @override
  Future<TStamp> stamp(String payload) {
    throw UnimplementedError();
  }
}

class _FakeKeyStore implements KeyStore {
  @override
  Future<String> createKeyPair({
    String? externalPublicKey,
    String? externalPrivateKey,
    bool isCompressed = true,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteKeyPair(String publicKey) async {}

  @override
  Future<List<String>> listKeyPairs() async => [];
}

void main() {
  group('OtpAuthProvider', () {
    test('initOtp returns bundle when wire response is valid', () async {
      final auth = _FakeAuthRepository();
      final provider = OtpAuthProvider(
        auth: auth,
        signer: _FakeSigner(),
        keyStore: _FakeKeyStore(),
      );

      final result = await provider.initOtp(
        contact: 'user@example.com',
        otpType: 'OTP_TYPE_EMAIL',
      );

      expect(result.otpId, 'otp-1');
      expect(result.otpEncryptionTargetBundle, 'bundle-1');
    });

    test('initOtp throws AuthException when otpId missing', () async {
      final auth = _FakeAuthRepository()
        ..initResponse = ProxyTInitOtpV2Response(
          otpId: '',
          otpEncryptionTargetBundle: 'bundle-1',
        );
      final provider = OtpAuthProvider(
        auth: auth,
        signer: _FakeSigner(),
        keyStore: _FakeKeyStore(),
      );

      expect(
        () => provider.initOtp(contact: 'a@b.c', otpType: 'OTP_TYPE_EMAIL'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('InitOtpUseCase', () {
    test('delegates to OtpAuthProvider', () async {
      final auth = _FakeAuthRepository();
      final provider = OtpAuthProvider(
        auth: auth,
        signer: _FakeSigner(),
        keyStore: _FakeKeyStore(),
      );
      final useCase = InitOtpUseCase(provider);

      final result = await useCase.call(
        contact: 'user@example.com',
        otpType: 'OTP_TYPE_EMAIL',
      );

      expect(result.otpId, 'otp-1');
    });
  });
}
