import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:zeroxkey_attested_stamper/zeroxkey_attested_stamper.dart';

class _FixedSigner implements AttestedSigner {
  @override
  final String publicKey;
  final String signature;
  String? signedBody;

  _FixedSigner(this.publicKey, this.signature);

  @override
  String sign(String body) {
    signedBody = body;
    return signature;
  }
}

class _ThrowingSigner implements AttestedSigner {
  @override
  String get publicKey => 'public-key';

  @override
  String sign(String body) => throw StateError('provider leaked secret-token');
}

void main() {
  test('matches shared vector and normalizes only high-S signatures', () async {
    final raw =
        File('../../testdata/turnkey-attested-stamp.json').readAsBytesSync();
    expect(sha256.convert(raw).toString(),
        '54d576e55629ae628df762354af91f630d5ce275aa3d5b78423dfe78f4d5661a'); // gitleaks:allow
    final vector = jsonDecode(utf8.decode(raw)) as Map<String, dynamic>;
    final signer = _FixedSigner(
      vector['publicKey'] as String,
      vector['highDerHex'] as String,
    );
    final stamper = AttestedStamper(
      identity: 'verification-token',
      scheme: AttestedScheme.p256VerificationToken,
      signer: signer,
    );

    final stamp = await stamper.stamp(vector['bodyUtf8'] as String);
    expect(stamp.stampHeaderName, vector['header']);
    expect(stamp.stampHeaderValue, isNot(contains('=')));
    expect(signer.signedBody, vector['bodyUtf8']);
    final wire = jsonDecode(utf8.decode(
            base64Url.decode(base64Url.normalize(stamp.stampHeaderValue))))
        as Map<String, dynamic>;
    expect(wire, {
      'publicKeyAttestation': 'verification-token',
      'scheme': 'STAMP_ATTESTED_SCHEME_P256_VERIFICATION_TOKEN',
      'publicKey': vector['publicKey'],
      'signature': vector['lowDerHex'],
    });
    expect(stamper.toString(), isNot(contains('verification-token')));

    final lowSigner = _FixedSigner(
      vector['publicKey'] as String,
      vector['lowDerHex'] as String,
    );
    final lowStamp = await AttestedStamper(
      identity: 'verification-token',
      scheme: AttestedScheme.p256VerificationToken,
      signer: lowSigner,
    ).stamp(vector['bodyUtf8'] as String);
    final lowWire = jsonDecode(utf8.decode(
            base64Url.decode(base64Url.normalize(lowStamp.stampHeaderValue))))
        as Map<String, dynamic>;
    expect(lowWire['signature'], vector['lowDerHex']);
  });

  test('generated key signs exact body and mutation fails verification',
      () async {
    final key = P256AttestedKey.fromPrivateKeyHex('07'.padLeft(64, '0'));
    const body = '{"organizationId":"org","timestampMs":"1"} ';
    final signature = key.sign(body);
    expect(key.verify(body, signature), isTrue);
    expect(key.verify('${body}x', signature), isFalse);
  });

  test('rejects unknown schemes without exposing the identity', () {
    expect(() => AttestedScheme.fromWire('unknown'), throwsArgumentError);
    final signer = _FixedSigner('key', 'signature');
    final stamper = AttestedStamper(
      identity: 'secret-oidc-token',
      scheme: AttestedScheme.p256Oidc,
      signer: signer,
    );
    expect(stamper.toString(), isNot(contains('secret-oidc-token')));
  });

  test('does not expose signer provider errors', () async {
    final stamper = AttestedStamper(
      identity: 'secret-token',
      scheme: AttestedScheme.p256VerificationToken,
      signer: _ThrowingSigner(),
    );
    await expectLater(
      stamper.stamp('{}'),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          isNot(contains('secret-token')),
        ),
      ),
    );
  });
}
