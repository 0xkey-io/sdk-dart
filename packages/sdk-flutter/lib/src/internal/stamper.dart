import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zeroxkey_core/zeroxkey_core.dart' show Signer, KeyStore;
import 'package:zeroxkey_crypto/zeroxkey_crypto.dart';
import 'package:zeroxkey_api_key_stamper/zeroxkey_api_key_stamper.dart';
import 'package:zeroxkey_http/base.dart';

/// Stores private keys in secure storage and signs payloads.
///
/// Implements the core [Signer] port so the rest of the SDK depends on the
/// abstraction rather than this Flutter-specific implementation.
class SecureStorageStamper implements TStamper, Signer {
  static const _storage = FlutterSecureStorage();

  /// Optional public key associated with this stamper instance.
  String? publicKey;

  /// Constructor — optionally pass a public key at initialization.
  SecureStorageStamper({this.publicKey});

  /// ✅ Update the public key later
  void setPublicKey(String newPublicKey) {
    publicKey = newPublicKey;
  }

  /// ✅ List all stored key pairs (public keys)
  static Future<List<String>> listKeyPairs() async {
    final all = await _storage.readAll();
    return all.keys.toList();
  }

  /// ✅ Delete all key pairs
  static Future<void> clearKeyPairs() async {
    final keys = await listKeyPairs();
    for (final key in keys) {
      await deleteKeyPair(key);
    }
  }

  /// ✅ Create a new key pair (or store an external one)
  static Future<String> createKeyPair({
    String? externalPublicKey,
    String? externalPrivateKey,
    isCompressed = true,
  }) async {
    String privateKey;
    String publicKey;

    if (externalPrivateKey != null && externalPublicKey != null) {
      privateKey = externalPrivateKey;
      publicKey = externalPublicKey;
    } else {
      final pair = await generateP256KeyPair();
      privateKey = pair.privateKey;
      if (isCompressed) {
        publicKey = pair.publicKey;
      } else {
        publicKey = pair.publicKeyUncompressed;
      }
    }

    // Store private key securely with public key as the identifier
    await _storage.write(key: publicKey, value: privateKey);
    return publicKey;
  }

  /// ✅ Delete a key pair by its public key
  static Future<void> deleteKeyPair(String publicKeyHex) async {
    await _storage.delete(key: publicKeyHex);
  }

  /// ✅ Get the private key associated with a public key
  static Future<String?> _getPrivateKey(String publicKeyHex) async {
    return await _storage.read(key: publicKeyHex);
  }

  /// ✅ Sign a payload with the key pair (stamping)
  ///
  /// If [publicKeyHex] is provided, it takes priority.
  /// Otherwise, the instance-level [publicKey] will be used.
  /// If neither is available, an exception is thrown.
  @override
  Future<TStamp> stamp(String payload, {String? publicKeyHex}) async {
    final keyToUse = publicKeyHex ?? publicKey;
    if (keyToUse == null) {
      throw Exception(
        "No public key provided. Pass one to `stamp()` or set it with `setPublicKey()`.",
      );
    }

    final privateKey = await _getPrivateKey(keyToUse);
    if (privateKey == null) {
      throw Exception("No private key found for public key: $keyToUse");
    }

    final stamper = ApiKeyStamper(
      ApiKeyStamperConfig(
        apiPublicKey: keyToUse,
        apiPrivateKey: privateKey,
      ),
    );

    final result = await stamper.stamp(payload);
    return TStamp(
      stampHeaderName: result.stampHeaderName,
      stampHeaderValue: result.stampHeaderValue,
    );
  }

  Future<String> sign(String content,
      {SignatureFormat format = SignatureFormat.der}) async {
    final keyToUse = publicKey;
    if (keyToUse == null) {
      throw Exception(
        "No public key provided. Set it with `setPublicKey()` before signing.",
      );
    }

    final privateKey = await _getPrivateKey(keyToUse);
    if (privateKey == null) {
      throw Exception("No private key found for public key: $keyToUse");
    }

    final stamper = ApiKeyStamper(
      ApiKeyStamperConfig(
        apiPublicKey: keyToUse,
        apiPrivateKey: privateKey,
      ),
    );

    return stamper.sign(content, format);
  }
}

/// [KeyStore] adapter over [SecureStorageStamper]'s static key-management API.
///
/// Kept separate from the [Signer] surface (ISP) so signing consumers don't
/// depend on key lifecycle operations they don't use.
class SecureStorageKeyStore implements KeyStore {
  const SecureStorageKeyStore();

  @override
  Future<String> createKeyPair({
    String? externalPublicKey,
    String? externalPrivateKey,
    bool isCompressed = true,
  }) {
    return SecureStorageStamper.createKeyPair(
      externalPublicKey: externalPublicKey,
      externalPrivateKey: externalPrivateKey,
      isCompressed: isCompressed,
    );
  }

  @override
  Future<List<String>> listKeyPairs() => SecureStorageStamper.listKeyPairs();

  @override
  Future<void> deleteKeyPair(String publicKey) =>
      SecureStorageStamper.deleteKeyPair(publicKey);
}
