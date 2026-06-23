import 'dart:convert';
import 'dart:typed_data';

import 'constant.dart';
import 'crypto.dart';
import 'package:pointycastle/export.dart';
import 'package:zeroxkey_encoding/zeroxkey_encoding.dart';

/// 0xkey-native HPKE info string for enclave import/export and credential bundles.
const String zeroxkeyHpkeInfo = '0xkey_hpke';

Uint8List textToBytes(String value) => Uint8List.fromList(utf8.encode(value));

Uint8List labeledExtract(String label, Uint8List ikm, Uint8List suiteId) {
  final labeledIkm = buildLabeledIkm(textToBytes(label), ikm, suiteId);
  return hkdfExtract(labeledIkm, Uint8List(0));
}

class HpkeScheduleInfo {
  const HpkeScheduleInfo({required this.aesKeyInfo, required this.ivInfo});

  final Uint8List aesKeyInfo;
  final Uint8List ivInfo;
}

/// Resolve the HPKE key-schedule info used during AES key / nonce derivation.
///
/// - `null` or `'turnkey_hpke'`: legacy compatibility branch. It uses fixed
///   [AES_KEY_INFO] / [IV_INFO] constants and matches bundles produced without
///   an explicit [hpkeInfo] (or with the legacy identifier). Kept so the SDK
///   can still decrypt older ciphertext during migration. The `'turnkey_hpke'`
///   token is a functional wire-protocol domain-separation identifier, NOT
///   branding — it must stay byte-for-byte in sync with the reference crypto
///   implementation to preserve ciphertext interoperability.
/// - Any other string (e.g. `'0xkey_hpke'`): 0xkey-native branch. It performs
///   the full RFC 9180 labeled key schedule with the supplied info string as
///   the HPKE `info` parameter. This is the branch the 0xkey enclave and all
///   native SDK helpers use.
///
/// 0xkey-native flows MUST pass `hpkeInfo: zeroxkeyHpkeInfo` explicitly;
/// relying on the default is reserved for legacy interop only. Once no live
/// legacy ciphertext needs to be read, this branch can be removed in a
/// breaking release.
HpkeScheduleInfo getHpkeScheduleInfo([String? hpkeInfo]) {
  if (hpkeInfo == null || hpkeInfo == 'turnkey_hpke') {
    return HpkeScheduleInfo(aesKeyInfo: AES_KEY_INFO, ivInfo: IV_INFO);
  }

  final pskIdHash = labeledExtract('psk_id_hash', Uint8List(0), SUITE_ID_2);
  final infoHash =
      labeledExtract('info_hash', textToBytes(hpkeInfo), SUITE_ID_2);
  final keyScheduleContext = Uint8List(1 + pskIdHash.length + infoHash.length)
    ..[0] = 0
    ..setRange(1, 1 + pskIdHash.length, pskIdHash)
    ..setRange(
        1 + pskIdHash.length, 1 + pskIdHash.length + infoHash.length, infoHash);

  return HpkeScheduleInfo(
    aesKeyInfo: buildLabeledInfo(
        textToBytes('key'), keyScheduleContext, SUITE_ID_2, 32),
    ivInfo: buildLabeledInfo(
        textToBytes('base_nonce'), keyScheduleContext, SUITE_ID_2, 12),
  );
}

Uint8List hmacSha256(Uint8List key, Uint8List data) {
  final hmac = HMac(SHA256Digest(), 64);
  hmac.init(KeyParameter(key));
  return hmac.process(data);
}

/// HKDF-extract (JS: `extract(sha256, ikm, salt)`).
/// If [salt] is null, uses a zeroed array of length 32 (SHA-256 digest size).
Uint8List hkdfExtract(Uint8List ikm, [Uint8List? salt]) {
  const hashLen = 32; // for SHA-256
  final usedSalt = salt ?? Uint8List(hashLen);
  return hmacSha256(usedSalt, ikm);
}

/// HKDF-expand (JS: `expand(sha256, prk, info, len)`).
/// Produces [length] bytes of output key material.
/// If [info] is null, uses an empty array.
Uint8List hkdfExpand(Uint8List prk, [Uint8List? info, int length = 32]) {
  const hashLen = 32; // for SHA-256
  if (length > 255 * hashLen) {
    throw ArgumentError('length cannot exceed 255 * hashLen');
  }
  final usedInfo = info ?? Uint8List(0);
  final blocks = (length + hashLen - 1) ~/ hashLen;

  final okm = Uint8List(blocks * hashLen);
  Uint8List tBlock = Uint8List(0);

  for (int i = 0; i < blocks; i++) {
    // T(i) = HMAC-Hash(prk, T(i-1) || info || counter)
    final buffer = Uint8List(tBlock.length + usedInfo.length + 1);
    buffer.setAll(0, tBlock);
    buffer.setAll(tBlock.length, usedInfo);
    buffer[buffer.length - 1] = i + 1; // counter
    tBlock = hmacSha256(prk, buffer);
    okm.setAll(i * hashLen, tBlock);
  }
  return okm.sublist(0, length);
}

/// Perform HKDF extract and expand operations.
///
/// - [sharedSecret]: The shared secret used as the salt for the extract phase.
/// - [ikm]: Input key material.
/// - [info]: Context and application-specific information.
/// - [len]: The desired output length in bytes.
///
/// Returns a `Uint8List` containing the derived key of the specified length.
Uint8List extractAndExpand(
  Uint8List sharedSecret,
  Uint8List ikm,
  Uint8List info,
  int len,
) {
  final prk = hkdfExtract(ikm, sharedSecret);
  final okm = hkdfExpand(prk, info, len);
  return okm;
}

/// Formats an HPKE buffer into a JSON string with the encapsulated public key and ciphertext.
///
/// - [encryptedBuf]: The result of `hpkeAuthEncrypt` or `hpkeEncrypt` as a `Uint8List`.
///
/// Returns:
/// - A JSON string with "encappedPublic" and "ciphertext".
String formatHpkeBuf(Uint8List encryptedBuf) {
  final compressedSenderBuf = encryptedBuf.sublist(0, 33);
  final encryptedData = encryptedBuf.sublist(33);

  final encappedKeyBufHex = uint8ArrayToHexString(
    uncompressRawPublicKey(compressedSenderBuf),
  );

  final ciphertextHex = uint8ArrayToHexString(encryptedData);

  return jsonEncode({
    'encappedPublic': encappedKeyBufHex,
    'ciphertext': ciphertextHex,
  });
}

/// Encrypts data using Authenticated Hybrid Public Key Encryption (HPKE) standard.
///
/// - [plainTextBuf]: The plaintext data as a `Uint8List`.
/// - [targetKeyBuf]: The target public key as a `Uint8List`.
/// - [senderPriv]: The sender's private key as a hex string.
///
/// Returns:
/// - The encrypted data as a `Uint8List`.
Uint8List hpkeAuthEncrypt({
  required Uint8List plainTextBuf,
  required Uint8List targetKeyBuf,
  required String senderPriv,
  String? hpkeInfo,
}) {
  try {
    // Authenticated HPKE Mode
    final senderPrivBuf = uint8ArrayFromHexString(senderPriv);
    final senderPubBuf = getPublicKey(senderPrivBuf, isCompressed: false);

    final aad = buildAdditionalAssociatedData(senderPubBuf, targetKeyBuf);

    // Step 1: Generate Shared Secret
    final ss = deriveSS(targetKeyBuf, senderPriv);

    // Step 2: Generate the KEM context
    final kemContext =
        getKemContext(senderPubBuf, uint8ArrayToHexString(targetKeyBuf));

    // Step 3: Build the HKDF inputs for key derivation
    var ikm = buildLabeledIkm(LABEL_EAE_PRK, ss, SUITE_ID_1);
    var info =
        buildLabeledInfo(LABEL_SHARED_SECRET, kemContext, SUITE_ID_1, 32);
    final sharedSecret = extractAndExpand(Uint8List(0), ikm, info, 32);

    final scheduleInfo = getHpkeScheduleInfo(hpkeInfo);

    // Step 4: Derive the AES key
    ikm = buildLabeledIkm(LABEL_SECRET, Uint8List(0), SUITE_ID_2);
    info = scheduleInfo.aesKeyInfo;
    final key = extractAndExpand(sharedSecret, ikm, info, 32);

    // Step 5: Derive the initialization vector
    info = scheduleInfo.ivInfo;
    final iv = extractAndExpand(sharedSecret, ikm, info, 12);

    // Step 6: Encrypt the data using AES-GCM
    final encryptedData = aesGcmEncrypt(plainTextBuf, key, iv, aad);

    // Step 7: Concatenate the encapsulated key and the encrypted data for output
    final compressedSenderBuf = compressRawPublicKey(senderPubBuf);
    final result = Uint8List(compressedSenderBuf.length + encryptedData.length)
      ..setAll(0, compressedSenderBuf)
      ..setAll(compressedSenderBuf.length, encryptedData);

    return result;
  } catch (error) {
    throw ArgumentError('Unable to perform hpkeAuthEncrypt: $error');
  }
}

/// HPKE Encrypt Function
/// Encrypts data using the Hybrid Public Key Encryption (HPKE) standard (RFC 9180).
///
/// - [plainTextBuf]: The plaintext data to encrypt as a `Uint8List`.
/// - [targetKeyBuf]: The recipient's public key as an uncompressed `Uint8List` (in the form `0x04 || x || y`).
///
/// Returns:
/// - The encrypted data as a `Uint8List`, including the encapsulated public key and ciphertext.
///
/// Throws:
/// - [ArgumentError] if encryption fails.
Uint8List hpkeEncrypt({
  required Uint8List plainTextBuf,
  required Uint8List targetKeyBuf,
  String? hpkeInfo,
}) {
  try {
    // Standard HPKE Mode (Ephemeral Key Pair)
    final ephemeralKeyPair = generateP256KeyPair();
    final senderPrivBuf = uint8ArrayFromHexString(ephemeralKeyPair.privateKey);
    final senderPubBuf =
        uint8ArrayFromHexString(ephemeralKeyPair.publicKeyUncompressed);

    final aad = buildAdditionalAssociatedData(senderPubBuf, targetKeyBuf);

    // Step 1: Generate Shared Secret
    final ss = deriveSS(targetKeyBuf, uint8ArrayToHexString(senderPrivBuf));

    // Step 2: Generate the KEM context
    final kemContext =
        getKemContext(senderPubBuf, uint8ArrayToHexString(targetKeyBuf));

    // Step 3: Build the HKDF inputs for key derivation
    var ikm = buildLabeledIkm(LABEL_EAE_PRK, ss, SUITE_ID_1);
    var info =
        buildLabeledInfo(LABEL_SHARED_SECRET, kemContext, SUITE_ID_1, 32);
    final sharedSecret = extractAndExpand(Uint8List(0), ikm, info, 32);

    final scheduleInfo = getHpkeScheduleInfo(hpkeInfo);

    // Step 4: Derive the AES key
    ikm = buildLabeledIkm(LABEL_SECRET, Uint8List(0), SUITE_ID_2);
    info = scheduleInfo.aesKeyInfo;
    final key = extractAndExpand(sharedSecret, ikm, info, 32);

    // Step 5: Derive the initialization vector
    info = scheduleInfo.ivInfo;
    final iv = extractAndExpand(sharedSecret, ikm, info, 12);

    // Step 6: Encrypt the data using AES-GCM
    final encryptedData = aesGcmEncrypt(plainTextBuf, key, iv, aad);

    // Step 7: Concatenate the encapsulated key and the encrypted data for output
    final compressedSenderBuf = compressRawPublicKey(senderPubBuf);
    final result = Uint8List(compressedSenderBuf.length + encryptedData.length)
      ..setAll(0, compressedSenderBuf)
      ..setAll(compressedSenderBuf.length, encryptedData);

    return result;
  } catch (error) {
    throw ArgumentError('Unable to perform hpkeEncrypt: $error');
  }
}

/// HPKE Decrypt Function
/// Decrypts data using the Hybrid Public Key Encryption (HPKE) standard (RFC 9180).
///
/// - [ciphertextBuf]: The ciphertext as a `Uint8List`.
/// - [encappedKeyBuf]: The encapsulated key as a `Uint8List`.
/// - [receiverPriv]: The receiver's private key as a hexadecimal string.
///
/// Returns:
/// - The decrypted data as a `Uint8List`.
Uint8List hpkeDecrypt({
  required Uint8List ciphertextBuf,
  required Uint8List encappedKeyBuf,
  required String receiverPriv,
  String? hpkeInfo,
}) {
  try {
    final receiverPubBuf = getPublicKey(
      uint8ArrayFromHexString(receiverPriv),
      isCompressed: false,
    );

    final aad = buildAdditionalAssociatedData(encappedKeyBuf,
        receiverPubBuf); // Eventually we want users to be able to pass in aad as optional

    // Step 1: Generate the Shared Secret
    final ss = deriveSS(encappedKeyBuf, receiverPriv);

    // Step 2: Generate the KEM context
    final kemContext = getKemContext(
      encappedKeyBuf,
      receiverPubBuf
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join(),
    );

    // Step 3: Build the HKDF inputs for key derivation
    final ikmEaePrk = buildLabeledIkm(LABEL_EAE_PRK, ss, SUITE_ID_1);
    final infoSharedSecret =
        buildLabeledInfo(LABEL_SHARED_SECRET, kemContext, SUITE_ID_1, 32);
    final sharedSecret =
        extractAndExpand(Uint8List(0), ikmEaePrk, infoSharedSecret, 32);

    final scheduleInfo = getHpkeScheduleInfo(hpkeInfo);

    // Step 4: Derive the AES key
    final ikmSecret = buildLabeledIkm(LABEL_SECRET, Uint8List(0), SUITE_ID_2);
    final key =
        extractAndExpand(sharedSecret, ikmSecret, scheduleInfo.aesKeyInfo, 32);

    // Step 5: Derive the initialization vector
    final iv = extractAndExpand(
      sharedSecret,
      ikmSecret,
      scheduleInfo.ivInfo,
      12,
    );

    // Step 6: Decrypt the data using AES-GCM
    final decryptedData = aesGcmDecrypt(ciphertextBuf, key, iv, aad);
    return decryptedData;
  } catch (error) {
    throw Exception('Unable to perform hpkeDecrypt: $error');
  }
}
