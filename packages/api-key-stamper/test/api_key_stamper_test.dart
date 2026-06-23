import 'package:test/test.dart';
import 'package:zeroxkey_api_key_stamper/zeroxkey_api_key_stamper.dart';
import 'package:zeroxkey_crypto/zeroxkey_crypto.dart';

void main() {
  test('stamps requests with X-Stamp header', () async {
    final keyPair = generateP256KeyPair();
    final stamper = ApiKeyStamper(
      ApiKeyStamperConfig(
        apiPrivateKey: keyPair.privateKey,
        apiPublicKey: keyPair.publicKey,
      ),
    );

    final stamp = await stamper.stamp('{"organizationId":"org-123"}');
    expect(stamp.stampHeaderName, 'X-Stamp');
    expect(stamp.stampHeaderValue, isNotEmpty);
  });
}
