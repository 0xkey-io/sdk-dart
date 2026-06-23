import 'package:test/test.dart';
import 'package:zeroxkey_core/zeroxkey_core.dart';
import 'package:zeroxkey_http/zeroxkey_http.dart';

class _MockStamper implements TStamper {
  @override
  Future<TStamp> stamp(String content) async {
    return TStamp(stampHeaderName: 'X-Stamp', stampHeaderValue: 'mock');
  }
}

/// Fake passkey repository that fails with a mapped API error, to verify the
/// provider rethrows core exceptions instead of swallowing them.
class _ThrowingPasskeyRepository implements PasskeyRepository {
  @override
  Future<TStampLoginResponse> stampLogin({
    required ZeroXKeyClient client,
    required TStampLoginBody body,
  }) async {
    throw const ApiException(code: 16, message: 'unauthenticated');
  }
}

void main() {
  group('PasskeyAuthProvider', () {
    test('rethrows mapped ApiException without wrapping', () async {
      final provider =
          PasskeyAuthProvider(passkey: _ThrowingPasskeyRepository());

      expect(
        () => provider.loginWithPasskey(
          client: ZeroXKeyClient(
            config: THttpConfig(baseUrl: 'https://api.0xkey.io'),
            stamper: _MockStamper(),
          ),
          publicKey: 'pk',
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('exposes a stable provider name', () {
      final provider =
          PasskeyAuthProvider(passkey: _ThrowingPasskeyRepository());
      expect(provider.name, 'passkey');
    });
  });
}
