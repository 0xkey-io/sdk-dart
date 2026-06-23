import 'dart:convert';

import 'package:test/test.dart';
import 'package:zeroxkey_core/zeroxkey_core.dart';

/// Builds a minimal JWT (header.payload.signature) with the given payload map.
String _jwt(Map<String, dynamic> payload) {
  String seg(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${seg({'alg': 'none'})}.${seg(payload)}.sig';
}

void main() {
  group('VerificationTokenCodec', () {
    test('decodes snake_case wire fields from a JWT', () {
      final token = _jwt({
        'contact': 'user@example.com',
        'exp': 1893456000,
        'id': 'token-1',
        'public_key': 'pubkey-abc',
        'verification_type': 'EMAIL',
        'organization_id': 'org-1',
      });

      final decoded = VerificationTokenCodec.fromJwt(token);
      expect(decoded.id, 'token-1');
      expect(decoded.publicKey, 'pubkey-abc');
      expect(decoded.contact, 'user@example.com');
      expect(decoded.organizationId, 'org-1');
    });

    test('throws on a malformed token', () {
      expect(
        () => VerificationTokenCodec.fromJwt('not-a-jwt'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('ClientSignatureCodec.forLogin', () {
    test('binds the client signature key to the token public key', () {
      final token = _jwt({
        'contact': 'user@example.com',
        'exp': 1893456000,
        'id': 'token-1',
        'public_key': 'pubkey-abc',
        'verification_type': 'EMAIL',
        'organization_id': 'org-1',
      });

      const codec = ClientSignatureCodec();
      final payload = codec.forLogin(verificationToken: token);

      expect(payload.clientSignaturePublicKey, 'pubkey-abc');
      final message = jsonDecode(payload.message) as Map<String, dynamic>;
      expect(message['tokenId'], 'token-1');
    });

    test('throws when the token has no public key', () {
      final token = _jwt({
        'contact': 'user@example.com',
        'exp': 1893456000,
        'id': 'token-1',
        'verification_type': 'EMAIL',
        'organization_id': 'org-1',
      });

      const codec = ClientSignatureCodec();
      expect(
        () => codec.forLogin(verificationToken: token),
        throwsA(isA<StateError>()),
      );
    });
  });
}
