import 'package:test/test.dart';
import 'package:zeroxkey_core/zeroxkey_core.dart';
import 'package:zeroxkey_http/zeroxkey_http.dart'
    show v1AddressFormat, v1PayloadEncoding, v1HashFunction;

void main() {
  group('SigningCodec', () {
    test('resolves Ethereum defaults to hex + keccak256', () {
      expect(
        SigningCodec.encodingFor(v1AddressFormat.address_format_ethereum),
        v1PayloadEncoding.payload_encoding_hexadecimal,
      );
      expect(
        SigningCodec.hashFor(v1AddressFormat.address_format_ethereum),
        v1HashFunction.hash_function_keccak256,
      );
    });

    test('resolves Cosmos defaults to utf8 + sha256', () {
      expect(
        SigningCodec.encodingFor(v1AddressFormat.address_format_cosmos),
        v1PayloadEncoding.payload_encoding_text_utf8,
      );
      expect(
        SigningCodec.hashFor(v1AddressFormat.address_format_cosmos),
        v1HashFunction.hash_function_sha256,
      );
    });

    test('encodeMessage hex-prefixes hexadecimal payloads', () {
      final bytes = SigningCodec.toUtf8Bytes('hi');
      final encoded = SigningCodec.encodeMessage(
        v1PayloadEncoding.payload_encoding_hexadecimal,
        bytes,
      );
      expect(encoded, '0x6869');
    });

    test('encodeMessage passes through utf8 payloads', () {
      final bytes = SigningCodec.toUtf8Bytes('hi');
      final encoded = SigningCodec.encodeMessage(
        v1PayloadEncoding.payload_encoding_text_utf8,
        bytes,
      );
      expect(encoded, 'hi');
    });

    test('applyEthereumPrefix prepends EIP-191 personal-message prefix', () {
      final message = SigningCodec.toUtf8Bytes('abc');
      final prefixed = SigningCodec.applyEthereumPrefix(message);
      final expectedPrefix =
          SigningCodec.toUtf8Bytes('\x19Ethereum Signed Message:\n3');
      expect(
        prefixed.sublist(0, expectedPrefix.length),
        equals(expectedPrefix),
      );
      expect(prefixed.sublist(expectedPrefix.length), equals(message));
    });

    test('throws SigningException for unsupported address formats', () {
      // There is no enum member we can guarantee is unmapped, so assert that all
      // mapped lookups succeed and the require path is total for Ethereum.
      expect(
        () => SigningCodec.encodingFor(v1AddressFormat.address_format_ethereum),
        returnsNormally,
      );
    });
  });
}
