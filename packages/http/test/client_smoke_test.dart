import 'package:test/test.dart';
import 'package:zeroxkey_http/zeroxkey_http.dart';

class _MockStamper implements TStamper {
  @override
  Future<TStamp> stamp(String content) async {
    return TStamp(
      stampHeaderName: 'X-Stamp',
      stampHeaderValue: 'mock-stamp',
    );
  }
}

void main() {
  test('ZeroXKeyClient requires explicit baseUrl', () {
    expect(
      () => ZeroXKeyClient(
        config: THttpConfig(baseUrl: ''),
        stamper: _MockStamper(),
      ),
      throwsException,
    );
  });

  test('Proxy models deserialize auth proxy config payload', () {
    final config = ProxyTGetWalletKitConfigResponse.fromJson({
      'enabledProviders': ['email', 'passkey'],
      'sessionExpirationSeconds': '900',
      'organizationId': 'org-123',
      'otpLength': '6',
      'otpAlphanumeric': false,
    });

    expect(config.otpLength, '6');
    expect(config.enabledProviders, ['email', 'passkey']);
  });
}
