import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:ecdsa/ecdsa.dart';
import 'package:elliptic/elliptic.dart';
import 'package:zeroxkey_encoding/zeroxkey_encoding.dart';

const attestedStampHeaderName = 'X-Stamp-Attested';

enum AttestedScheme {
  p256Oidc('STAMP_ATTESTED_SCHEME_P256_OIDC'),
  p256VerificationToken('STAMP_ATTESTED_SCHEME_P256_VERIFICATION_TOKEN');

  const AttestedScheme(this.wireValue);
  final String wireValue;

  static AttestedScheme fromWire(String value) => switch (value) {
        'STAMP_ATTESTED_SCHEME_P256_OIDC' => p256Oidc,
        'STAMP_ATTESTED_SCHEME_P256_VERIFICATION_TOKEN' =>
          p256VerificationToken,
        _ => throw ArgumentError.value(value, 'value', 'unsupported scheme'),
      };
}

abstract interface class AttestedSigner {
  String get publicKey;
  String sign(String body);
}

final class P256AttestedKey implements AttestedSigner {
  P256AttestedKey._(this._privateKey);

  factory P256AttestedKey.generate() {
    final curve = getP256();
    return P256AttestedKey._(curve.generatePrivateKey());
  }

  factory P256AttestedKey.fromPrivateKeyHex(String privateKeyHex) {
    return P256AttestedKey._(PrivateKey.fromHex(getP256(), privateKeyHex));
  }

  final PrivateKey _privateKey;

  @override
  String get publicKey =>
      _privateKey.curve.privateToPublicKey(_privateKey).toHex();

  @override
  String sign(String body) {
    final signature = deterministicSign(
      _privateKey,
      sha256.convert(utf8.encode(body)).bytes,
    );
    final halfOrder = _privateKey.curve.n >> 1;
    if (signature.S > halfOrder) {
      signature.S = _privateKey.curve.n - signature.S;
    }
    return signature.toDERHex();
  }

  bool verify(String body, String derSignatureHex) {
    try {
      final signature = Signature.fromDERHex(derSignatureHex);
      return ecdsaVerify(
        PublicKey.fromHex(_privateKey.curve, publicKey),
        sha256.convert(utf8.encode(body)).bytes,
        signature,
      );
    } on Object {
      return false;
    }
  }

  @override
  String toString() => 'P256AttestedKey{configured:true}';
}

bool ecdsaVerify(PublicKey key, List<int> hash, Signature signature) =>
    verify(key, hash, signature);

final class AttestedStamper implements TStamper {
  AttestedStamper({
    required String identity,
    required this.scheme,
    required this.signer,
  }) : _identity = identity {
    if (identity.isEmpty || signer.publicKey.isEmpty) {
      throw ArgumentError('attested identity and public key are required');
    }
  }

  final String _identity;
  final AttestedScheme scheme;
  final AttestedSigner signer;

  @override
  Future<TStamp> stamp(String input) async {
    late final String signed;
    try {
      signed = signer.sign(input);
    } on Object {
      throw StateError('attested signer failed');
    }
    final signature = _normalizeLowS(signed);
    final wire = jsonEncode({
      'publicKeyAttestation': _identity,
      'scheme': scheme.wireValue,
      'publicKey': signer.publicKey,
      'signature': signature,
    });
    return TStamp(
      stampHeaderName: attestedStampHeaderName,
      stampHeaderValue: base64Url.encode(utf8.encode(wire)).replaceAll('=', ''),
    );
  }

  String _normalizeLowS(String derHex) {
    final signature = Signature.fromDERHex(derHex);
    final order = getP256().n;
    if (signature.R <= BigInt.zero ||
        signature.R >= order ||
        signature.S <= BigInt.zero ||
        signature.S >= order) {
      throw FormatException('invalid P-256 DER signature');
    }
    if (signature.S > (order >> 1)) {
      signature.S = order - signature.S;
    }
    return signature.toDERHex();
  }

  @override
  String toString() =>
      'AttestedStamper{configured:true,scheme:${scheme.wireValue}}';
}
