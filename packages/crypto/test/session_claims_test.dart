import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:test/test.dart';
import 'package:zeroxkey_crypto/zeroxkey_crypto.dart';

String _unpadded(List<int> bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');

({String token, String publicKey}) _token(Map<String, dynamic> claims) {
  final domain = ECDomainParameters('prime256v1');
  final privateKey = ECPrivateKey(BigInt.from(7), domain);
  final publicKey = ECPublicKey(domain.G * BigInt.from(7), domain);
  final header = _unpadded(utf8.encode('{"alg":"ES256","typ":"JWT"}'));
  final payload = _unpadded(utf8.encode(jsonEncode(claims)));
  final input = '$header.$payload';
  final signer = Signer('SHA-256/DET-ECDSA')
    ..init(true, PrivateKeyParameter<ECPrivateKey>(privateKey));
  final signature = signer.generateSignature(utf8.encode(input)) as ECSignature;
  final raw = Uint8List(64)
    ..setRange(0, 32, _fixed(signature.r))
    ..setRange(32, 64, _fixed(signature.s));
  final point = publicKey.Q!;
  final publicBytes = Uint8List.fromList([
    4,
    ..._fixed(point.x!.toBigInteger()!),
    ..._fixed(point.y!.toBigInteger()!),
  ]);
  return (token: '$input.${_unpadded(raw)}', publicKey: _hex(publicBytes));
}

List<int> _fixed(BigInt value) {
  final hex = value.toRadixString(16).padLeft(64, '0');
  return List.generate(
      32, (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16));
}

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() {
  test(
      'verifies ES256 raw signature and exposes scope only as untrusted metadata',
      () {
    final value = _token({
      'sub': 'user',
      'org': 'org',
      'type': 'SESSION_TYPE_READ_WRITE',
      'pub': 'session-key',
      'exp': 4102444800,
      'sessionProfileId': 'profile',
      'scope': 'root:write',
    });
    final claims = verifyAndDecodeSessionClaims(value.token, value.publicKey);
    expect(claims.userId, 'user');
    expect(claims.organizationId, 'org');
    expect(claims.sessionProfileId, 'profile');
    expect(claims.untrustedScope, 'root:write');
    expect(claims.toString(), isNot(contains(value.token)));
  });

  test('rejects conflicting aliases, expiry, and a changed raw signature', () {
    final conflicting = _token({
      'sub': 'user',
      'org': 'org',
      'exp': 4102444800,
      'session_profile_id': 'a',
      'sessionProfileId': 'b',
    });
    expect(
        () => verifyAndDecodeSessionClaims(
            conflicting.token, conflicting.publicKey),
        throwsFormatException);
    final expired = _token({'sub': 'user', 'org': 'org', 'exp': 1});
    expect(() => verifyAndDecodeSessionClaims(expired.token, expired.publicKey),
        throwsFormatException);
    final tampered =
        '${conflicting.token.substring(0, conflicting.token.length - 1)}A';
    expect(() => verifyAndDecodeSessionClaims(tampered, conflicting.publicKey),
        throwsFormatException);
  });
}
