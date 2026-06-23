import 'dart:convert';

import 'package:zeroxkey_http/zeroxkey_http.dart';

/// Pure-Dart client-signature payload builder for OTP login/signup flows.
class ClientSignaturePayload {
  final String message;
  final String clientSignaturePublicKey;

  const ClientSignaturePayload({
    required this.message,
    required this.clientSignaturePublicKey,
  });
}

class ClientSignatureCodec {
  const ClientSignatureCodec();

  ClientSignaturePayload forLogin({
    required String verificationToken,
    String? sessionPublicKey,
  }) {
    final decoded = VerificationTokenCodec.fromJwt(verificationToken);
    if (decoded.publicKey == null || decoded.publicKey!.isEmpty) {
      throw StateError('Verification token is missing a public key');
    }
    final resolvedSessionPublicKey = sessionPublicKey ?? decoded.publicKey!;
    final usage = v1LoginUsage(publicKey: resolvedSessionPublicKey);
    final payload = v1TokenUsage(
      login: usage,
      tokenId: decoded.id,
      type: v1UsageType.usage_type_login,
    );
    return ClientSignaturePayload(
      message: jsonEncode(payload.toJson()),
      clientSignaturePublicKey: decoded.publicKey!,
    );
  }

  ClientSignaturePayload forSignup({
    required String verificationToken,
    String? email,
    String? phoneNumber,
    List<v1ApiKeyParamsV2>? apiKeys,
    List<v1AuthenticatorParamsV2>? authenticators,
    List<v1OauthProviderParamsV2>? oauthProviders,
  }) {
    final decoded = VerificationTokenCodec.fromJwt(verificationToken);
    if (decoded.publicKey == null || decoded.publicKey!.isEmpty) {
      throw StateError('Verification token is missing a public key');
    }
    final usage = v1SignupUsageV2(
      email: email,
      phoneNumber: phoneNumber,
      apiKeys: apiKeys,
      authenticators: authenticators,
      oauthProviders: oauthProviders,
    );
    final payload = v1TokenUsage(
      signupV2: usage,
      tokenId: decoded.id,
      type: v1UsageType.usage_type_signup,
    );
    return ClientSignaturePayload(
      message: jsonEncode(payload.toJson()),
      clientSignaturePublicKey: decoded.publicKey!,
    );
  }
}

/// JWT payload decoder for verification tokens (snake_case wire fields).
class VerificationTokenCodec {
  final String contact;
  final int exp;
  final String id;
  final String? publicKey;
  final String verificationType;
  final String organizationId;

  const VerificationTokenCodec({
    required this.contact,
    required this.exp,
    required this.id,
    this.publicKey,
    required this.verificationType,
    required this.organizationId,
  });

  factory VerificationTokenCodec.fromJson(Map<String, dynamic> json) {
    final expRaw = json['exp'];
    final exp = expRaw is num ? expRaw.toInt() : int.parse(expRaw.toString());
    return VerificationTokenCodec(
      contact: json['contact'] as String,
      exp: exp,
      id: json['id'] as String,
      publicKey: json['public_key'] as String?,
      verificationType: json['verification_type'] as String,
      organizationId: json['organization_id'] as String,
    );
  }

  static VerificationTokenCodec fromJwt(String token) {
    final decoded = _decodeJwtPayload(token);
    if (decoded == null) {
      throw FormatException('Invalid JWT: could not decode payload');
    }
    return VerificationTokenCodec.fromJson(decoded);
  }
}

Map<String, dynamic>? _decodeJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length < 2) return null;
  try {
    final normalized =
        base64.normalize(parts[1].replaceAll('-', '+').replaceAll('_', '/'));
    return jsonDecode(utf8.decode(base64.decode(normalized)))
        as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}
