import 'dart:convert';
import 'dart:typed_data';

import 'package:zeroxkey_encoding/zeroxkey_encoding.dart'
    show uint8ArrayToHexString;
import 'package:zeroxkey_http/zeroxkey_http.dart'
    show v1AddressFormat, v1PayloadEncoding, v1HashFunction;

import '../errors/exceptions.dart';

/// Maps an address format to its default payload encoding + hash function.
class _AddressFormatConfig {
  final v1PayloadEncoding encoding;
  final v1HashFunction hashFunction;

  const _AddressFormatConfig({
    required this.encoding,
    required this.hashFunction,
  });
}

/// Pure (Flutter-free) message encoding helpers used by the signing flow.
///
/// Ported verbatim from the previous SDK helpers to preserve the exact on-wire
/// encoding/hash defaults per chain.
class SigningCodec {
  const SigningCodec._();

  static const _hex = v1PayloadEncoding.payload_encoding_hexadecimal;
  static const _utf8 = v1PayloadEncoding.payload_encoding_text_utf8;
  static const _sha256 = v1HashFunction.hash_function_sha256;
  static const _keccak = v1HashFunction.hash_function_keccak256;
  static const _na = v1HashFunction.hash_function_not_applicable;

  static const Map<v1AddressFormat, _AddressFormatConfig> _config = {
    v1AddressFormat.address_format_uncompressed:
        _AddressFormatConfig(encoding: _hex, hashFunction: _sha256),
    v1AddressFormat.address_format_compressed:
        _AddressFormatConfig(encoding: _hex, hashFunction: _sha256),
    v1AddressFormat.address_format_ethereum:
        _AddressFormatConfig(encoding: _hex, hashFunction: _keccak),
    v1AddressFormat.address_format_solana:
        _AddressFormatConfig(encoding: _hex, hashFunction: _na),
    v1AddressFormat.address_format_cosmos:
        _AddressFormatConfig(encoding: _utf8, hashFunction: _sha256),
    v1AddressFormat.address_format_tron:
        _AddressFormatConfig(encoding: _hex, hashFunction: _sha256),
    v1AddressFormat.address_format_sui:
        _AddressFormatConfig(encoding: _hex, hashFunction: _na),
    v1AddressFormat.address_format_aptos:
        _AddressFormatConfig(encoding: _hex, hashFunction: _na),
    v1AddressFormat.address_format_bitcoin_mainnet_p2pkh:
        _AddressFormatConfig(encoding: _hex, hashFunction: _sha256),
    v1AddressFormat.address_format_bitcoin_mainnet_p2sh:
        _AddressFormatConfig(encoding: _hex, hashFunction: _sha256),
    v1AddressFormat.address_format_bitcoin_mainnet_p2wpkh:
        _AddressFormatConfig(encoding: _hex, hashFunction: _sha256),
    v1AddressFormat.address_format_bitcoin_mainnet_p2wsh:
        _AddressFormatConfig(encoding: _hex, hashFunction: _sha256),
    v1AddressFormat.address_format_bitcoin_mainnet_p2tr:
        _AddressFormatConfig(encoding: _hex, hashFunction: _sha256),
    v1AddressFormat.address_format_bitcoin_testnet_p2pkh:
        _AddressFormatConfig(encoding: _hex, hashFunction: _sha256),
    v1AddressFormat.address_format_bitcoin_testnet_p2sh:
        _AddressFormatConfig(encoding: _hex, hashFunction: _sha256),
    v1AddressFormat.address_format_bitcoin_testnet_p2wpkh:
        _AddressFormatConfig(encoding: _hex, hashFunction: _sha256),
    v1AddressFormat.address_format_bitcoin_testnet_p2wsh:
        _AddressFormatConfig(encoding: _hex, hashFunction: _sha256),
    v1AddressFormat.address_format_bitcoin_testnet_p2tr:
        _AddressFormatConfig(encoding: _hex, hashFunction: _sha256),
    v1AddressFormat.address_format_bitcoin_signet_p2pkh:
        _AddressFormatConfig(encoding: _hex, hashFunction: _sha256),
    v1AddressFormat.address_format_bitcoin_signet_p2sh:
        _AddressFormatConfig(encoding: _hex, hashFunction: _sha256),
    v1AddressFormat.address_format_bitcoin_signet_p2wpkh:
        _AddressFormatConfig(encoding: _hex, hashFunction: _sha256),
    v1AddressFormat.address_format_bitcoin_signet_p2wsh:
        _AddressFormatConfig(encoding: _hex, hashFunction: _sha256),
    v1AddressFormat.address_format_bitcoin_signet_p2tr:
        _AddressFormatConfig(encoding: _hex, hashFunction: _sha256),
    v1AddressFormat.address_format_bitcoin_regtest_p2pkh:
        _AddressFormatConfig(encoding: _hex, hashFunction: _sha256),
    v1AddressFormat.address_format_bitcoin_regtest_p2sh:
        _AddressFormatConfig(encoding: _hex, hashFunction: _sha256),
    v1AddressFormat.address_format_bitcoin_regtest_p2wpkh:
        _AddressFormatConfig(encoding: _hex, hashFunction: _sha256),
    v1AddressFormat.address_format_bitcoin_regtest_p2wsh:
        _AddressFormatConfig(encoding: _hex, hashFunction: _sha256),
    v1AddressFormat.address_format_bitcoin_regtest_p2tr:
        _AddressFormatConfig(encoding: _hex, hashFunction: _sha256),
    v1AddressFormat.address_format_sei:
        _AddressFormatConfig(encoding: _utf8, hashFunction: _sha256),
    v1AddressFormat.address_format_xlm:
        _AddressFormatConfig(encoding: _hex, hashFunction: _na),
    v1AddressFormat.address_format_doge_mainnet:
        _AddressFormatConfig(encoding: _hex, hashFunction: _sha256),
    v1AddressFormat.address_format_doge_testnet:
        _AddressFormatConfig(encoding: _hex, hashFunction: _sha256),
    v1AddressFormat.address_format_ton_v3r2:
        _AddressFormatConfig(encoding: _hex, hashFunction: _na),
    v1AddressFormat.address_format_ton_v4r2:
        _AddressFormatConfig(encoding: _hex, hashFunction: _na),
    v1AddressFormat.address_format_ton_v5r1:
        _AddressFormatConfig(encoding: _hex, hashFunction: _na),
    v1AddressFormat.address_format_xrp:
        _AddressFormatConfig(encoding: _hex, hashFunction: _sha256),
  };

  static _AddressFormatConfig _require(v1AddressFormat format) {
    final cfg = _config[format];
    if (cfg == null) {
      throw SigningException('Unsupported address format: $format');
    }
    return cfg;
  }

  /// Default payload encoding for [format].
  static v1PayloadEncoding encodingFor(v1AddressFormat format) =>
      _require(format).encoding;

  /// Default hash function for [format].
  static v1HashFunction hashFor(v1AddressFormat format) =>
      _require(format).hashFunction;

  static Uint8List toUtf8Bytes(String value) =>
      Uint8List.fromList(utf8.encode(value));

  static String toUtf8String(Uint8List bytes) => utf8.decode(bytes);

  /// Encodes raw bytes into the string representation expected by the API.
  static String encodeMessage(v1PayloadEncoding encoding, Uint8List raw) {
    if (encoding == v1PayloadEncoding.payload_encoding_hexadecimal) {
      return '0x${uint8ArrayToHexString(raw)}';
    }
    return toUtf8String(raw);
  }

  /// Applies the EIP-191 personal-message prefix to [message] bytes.
  static Uint8List applyEthereumPrefix(Uint8List message) {
    final prefix =
        toUtf8Bytes('\x19Ethereum Signed Message:\n${message.length}');
    final combined = Uint8List(prefix.length + message.length)
      ..setRange(0, prefix.length, prefix)
      ..setRange(prefix.length, prefix.length + message.length, message);
    return combined;
  }
}
