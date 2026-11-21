import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:zeroxkey_crypto/src/constant.dart';
import 'package:zeroxkey_crypto/src/zeroxkey.dart';

const _clientPublicKey =
    '02a47b1d44ab3c7c5bd3e1d3c5e8b4b9d0f1e7a83a2bdd1f0c45e6a1f5f2a9c1b2';

Map<String, dynamic> _fixture() => jsonDecode(
      File('../../testdata/otp-encryption-target-bundle.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;

String _relabel(String bundle, String enclaveQuorumPublic) {
  final parsed = jsonDecode(bundle) as Map<String, dynamic>;
  parsed['enclaveQuorumPublic'] = enclaveQuorumPublic;
  return jsonEncode(parsed);
}

void main() {
  group('encryptOtpCodeToBundle', () {
    test('encrypts to targetPublic when the bundle verifies', () async {
      final fixture = _fixture();
      final encrypted = await encryptOtpCodeToBundle(
        otpCode: '123456',
        otpEncryptionTargetBundle: fixture['bundle'] as String,
        publicKey: _clientPublicKey,
        dangerouslyOverrideSignerPublicKey:
            fixture['signerPublicKey'] as String,
      );

      final parsed = jsonDecode(encrypted) as Map<String, dynamic>;
      expect(parsed['encappedPublic'], isNotEmpty);
      expect(parsed['ciphertext'], isNotEmpty);
    });

    test('defaults to the production signer signing key', () async {
      final fixture = _fixture();
      await expectLater(
        encryptOtpCodeToBundle(
          otpCode: '123456',
          otpEncryptionTargetBundle: fixture['bundle'] as String,
          publicKey: _clientPublicKey,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message.toString(),
          'message',
          contains(PRODUCTION_SIGNER_SIGN_PUBLIC_KEY),
        )),
      );
    });

    test('accepts a bundle that names the production signer key', () async {
      // The signature is not by the production key, so verification fails,
      // but only after the signer key check has passed.
      final bundle = _relabel(
        _fixture()['bundle'] as String,
        PRODUCTION_SIGNER_SIGN_PUBLIC_KEY,
      );
      await expectLater(
        encryptOtpCodeToBundle(
          otpCode: '123456',
          otpEncryptionTargetBundle: bundle,
          publicKey: _clientPublicKey,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('signature verification failed'),
        )),
      );
    });

    test('rejects a bundle that names the TLS fetcher encryption key',
        () async {
      final bundle = _relabel(
        _fixture()['bundle'] as String,
        PRODUCTION_TLS_FETCHER_ENCRYPT_PUBLIC_KEY,
      );
      await expectLater(
        encryptOtpCodeToBundle(
          otpCode: '123456',
          otpEncryptionTargetBundle: bundle,
          publicKey: _clientPublicKey,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects a tampered signature under the override key', () async {
      final fixture = _fixture();
      final parsed =
          jsonDecode(fixture['bundle'] as String) as Map<String, dynamic>;
      final data = parsed['data'] as String;
      parsed['data'] = '${data.substring(0, data.length - 2)}7e';
      await expectLater(
        encryptOtpCodeToBundle(
          otpCode: '123456',
          otpEncryptionTargetBundle: jsonEncode(parsed),
          publicKey: _clientPublicKey,
          dangerouslyOverrideSignerPublicKey:
              fixture['signerPublicKey'] as String,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
