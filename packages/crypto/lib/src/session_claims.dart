import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:zeroxkey_encoding/zeroxkey_encoding.dart';

final class UntrustedSessionClaims {
  const UntrustedSessionClaims({
    required this.userId,
    required this.organizationId,
    required this.expiresAt,
    this.sessionType,
    this.publicKey,
    this.sessionProfileId,
    this.untrustedScope,
  });

  final String userId;
  final String organizationId;
  final String? sessionType;
  final String? publicKey;
  final int expiresAt;
  final String? sessionProfileId;

  /// Wire-compatible token metadata only. Authorization must resolve the
  /// referenced Session Profile on the server instead of trusting this value.
  final String? untrustedScope;

  @override
  String toString() =>
      'UntrustedSessionClaims{userId:$userId,organizationId:$organizationId,'
      'expiresAt:$expiresAt,sessionProfileId:$sessionProfileId}';
}

UntrustedSessionClaims verifyAndDecodeSessionClaims(
  String jwt,
  String notarizerPublicKeyHex,
) {
  final parts = jwt.split('.');
  if (parts.length != 3)
    throw const FormatException('invalid session JWT format');
  final header = _decodeObject(parts[0]);
  if (header['alg'] != 'ES256') {
    throw const FormatException('session JWT must use ES256');
  }
  final signatureBytes = _decodePart(parts[2]);
  if (signatureBytes.length != 64) {
    throw const FormatException('invalid session JWT signature');
  }
  final domain = ECDomainParameters('prime256v1');
  final point =
      domain.curve.decodePoint(uint8ArrayFromHexString(notarizerPublicKeyHex));
  if (point == null)
    throw const FormatException('invalid session JWT public key');
  final signature = ECSignature(
    _bigInt(signatureBytes.sublist(0, 32)),
    _bigInt(signatureBytes.sublist(32)),
  );
  final verifier = Signer('SHA-256/ECDSA')
    ..init(false, PublicKeyParameter<ECPublicKey>(ECPublicKey(point, domain)));
  if (!verifier.verifySignature(
      utf8.encode('${parts[0]}.${parts[1]}'), signature)) {
    throw const FormatException('invalid session JWT signature');
  }

  final raw = _decodeObject(parts[1]);
  final userId = _requiredAlias(raw['sub'], raw['user_id']);
  final organizationId = _requiredAlias(raw['org'], raw['organization_id']);
  final sessionType = _optionalAlias(raw['type'], raw['session_type']);
  final publicKey = _optionalAlias(raw['pub'], raw['public_key']);
  final profileId =
      _optionalAlias(raw['session_profile_id'], raw['sessionProfileId']);
  final expiresAt = raw['exp'];
  if (expiresAt is! int)
    throw const FormatException('invalid session JWT claims');
  final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  if (expiresAt <= nowSeconds)
    throw const FormatException('session JWT is expired');
  return UntrustedSessionClaims(
    userId: userId,
    organizationId: organizationId,
    sessionType: sessionType,
    publicKey: publicKey,
    expiresAt: expiresAt,
    sessionProfileId: profileId,
    untrustedScope: raw['scope'] as String?,
  );
}

Map<String, dynamic> _decodeObject(String value) {
  try {
    return jsonDecode(utf8.decode(_decodePart(value))) as Map<String, dynamic>;
  } on Object {
    throw const FormatException('invalid session JWT claims');
  }
}

Uint8List _decodePart(String value) =>
    Uint8List.fromList(base64Url.decode(base64Url.normalize(value)));

BigInt _bigInt(List<int> bytes) =>
    BigInt.parse(bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
        radix: 16);

String? _optionalAlias(dynamic compact, dynamic legacy) {
  if (compact != null && compact is! String ||
      legacy != null && legacy is! String) {
    throw const FormatException('invalid session JWT claims');
  }
  if (compact != null && legacy != null && compact != legacy) {
    throw const FormatException('conflicting session JWT claim aliases');
  }
  return (compact as String?) ?? (legacy as String?);
}

String _requiredAlias(dynamic compact, dynamic legacy) {
  final value = _optionalAlias(compact, legacy);
  if (value == null || value.isEmpty) {
    throw const FormatException('invalid session JWT claims');
  }
  return value;
}
