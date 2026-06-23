import 'package:zeroxkey_api_key_stamper/zeroxkey_api_key_stamper.dart'
    show SignatureFormat;
import 'package:zeroxkey_http/zeroxkey_http.dart' show TStamp, TStamper;

export 'package:zeroxkey_api_key_stamper/zeroxkey_api_key_stamper.dart'
    show SignatureFormat;

/// Strategy abstraction over a credential capable of producing API stamps and
/// client signatures.
///
/// Implementations (secure-storage/API-key, passkey, future custody providers)
/// stay decoupled behind this port. A [Signer] is also a [TStamper] so it can be
/// injected directly into the generated `ZeroXKeyClient`.
///
/// Signature semantics implementations MUST preserve (wire compatibility):
/// P-256 ECDSA over SHA-256(utf8(message)), low-S normalized;
/// [SignatureFormat.raw] -> compact `r||s` hex (client signatures);
/// [SignatureFormat.der] -> DER hex (HTTP `X-Stamp`).
abstract class Signer implements TStamper {
  /// Public key currently used for signing/stamping, if any.
  String? get publicKey;

  /// Selects which stored key pair signs subsequent operations.
  void setPublicKey(String publicKey);

  /// Produces a raw/DER signature over [message] using the active key.
  Future<String> sign(String message, {SignatureFormat format});

  /// Produces an HTTP stamp header for [payload].
  @override
  Future<TStamp> stamp(String payload);
}

/// Manages the lifecycle of locally-held key pairs. Kept separate from [Signer]
/// (ISP) so signing consumers don't depend on key-management surface.
abstract class KeyStore {
  /// Creates (or imports) a key pair and returns its public key.
  Future<String> createKeyPair({
    String? externalPublicKey,
    String? externalPrivateKey,
    bool isCompressed,
  });

  /// Lists all stored public keys.
  Future<List<String>> listKeyPairs();

  /// Deletes the key pair identified by [publicKey].
  Future<void> deleteKeyPair(String publicKey);
}
