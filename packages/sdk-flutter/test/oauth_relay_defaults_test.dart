import 'package:test/test.dart';
import 'package:zeroxkey_sdk_flutter/src/utils/constants.dart';

void main() {
  group('hosted OAuth relay defaults', () {
    test('origin page is the 0xkey-operated host', () {
      expect(ZEROXKEY_OAUTH_ORIGIN_URL, 'https://oauth-origin.0xkey.io');
    });

    test('redirect relay is the 0xkey-operated host with a trailing slash', () {
      expect(ZEROXKEY_OAUTH_REDIRECT_URL, 'https://oauth-redirect.0xkey.io/');
    });

    test('scheme fallback yields the callback integrators register', () {
      expect(
        '$ZEROXKEY_OAUTH_REDIRECT_URL?scheme=${Uri.encodeComponent('myapp')}',
        'https://oauth-redirect.0xkey.io/?scheme=myapp',
      );
    });

    test('both defaults stay on the 0xkey.io zone', () {
      for (final url in [
        ZEROXKEY_OAUTH_ORIGIN_URL,
        ZEROXKEY_OAUTH_REDIRECT_URL,
      ]) {
        final uri = Uri.parse(url);
        expect(uri.scheme, 'https');
        expect(uri.host, endsWith('.0xkey.io'));
      }
    });
  });
}
