import 'package:test/test.dart';
import 'package:zeroxkey_core/zeroxkey_core.dart';
import 'package:zeroxkey_http/zeroxkey_http.dart'
    show
        externaldatav1Timestamp,
        v1AddressFormat,
        v1Curve,
        v1HashFunction,
        v1PathFormat,
        v1PayloadEncoding,
        v1SignRawPayloadResult,
        v1SignTransactionResult,
        v1TransactionType,
        v1WalletAccount;

/// Captures the arguments delegated to the signing repository.
class _CapturingSigningRepository implements SigningRepository {
  String? signWith;
  String? payload;
  v1PayloadEncoding? encoding;
  v1HashFunction? hashFunction;

  @override
  Future<v1SignRawPayloadResult> signRawPayload({
    required String signWith,
    required String payload,
    required v1PayloadEncoding encoding,
    required v1HashFunction hashFunction,
  }) async {
    this.signWith = signWith;
    this.payload = payload;
    this.encoding = encoding;
    this.hashFunction = hashFunction;
    return const v1SignRawPayloadResult(r: '01', s: '02', v: '00');
  }

  @override
  Future<v1SignTransactionResult> signTransaction({
    required String signWith,
    required String unsignedTransaction,
    required v1TransactionType type,
  }) {
    throw UnimplementedError();
  }
}

v1WalletAccount _account(v1AddressFormat format, String address) {
  const ts = externaldatav1Timestamp(seconds: '0', nanos: '0');
  return v1WalletAccount(
    walletAccountId: 'wa',
    organizationId: 'org',
    walletId: 'w',
    curve: v1Curve.curve_secp256k1,
    pathFormat: v1PathFormat.path_format_bip32,
    path: "m/44'/60'/0'/0/0",
    addressFormat: format,
    address: address,
    createdAt: ts,
    updatedAt: ts,
  );
}

void main() {
  group('SignMessageUseCase', () {
    test('applies EIP-191 prefix and hex encoding for Ethereum accounts',
        () async {
      final repo = _CapturingSigningRepository();
      final useCase = SignMessageUseCase(repo);

      await useCase.call(
        message: 'abc',
        walletAccount:
            _account(v1AddressFormat.address_format_ethereum, '0xabc'),
      );

      expect(repo.signWith, '0xabc');
      expect(repo.encoding, v1PayloadEncoding.payload_encoding_hexadecimal);
      expect(repo.hashFunction, v1HashFunction.hash_function_keccak256);
      // "\x19Ethereum Signed Message:\n3" + "abc" hex-encoded.
      final expectedBytes =
          SigningCodec.applyEthereumPrefix(SigningCodec.toUtf8Bytes('abc'));
      final expected = SigningCodec.encodeMessage(
        v1PayloadEncoding.payload_encoding_hexadecimal,
        expectedBytes,
      );
      expect(repo.payload, expected);
    });

    test('skips EIP-191 prefix when addEthereumPrefix is false', () async {
      final repo = _CapturingSigningRepository();
      final useCase = SignMessageUseCase(repo);

      await useCase.call(
        message: 'abc',
        walletAccount:
            _account(v1AddressFormat.address_format_ethereum, '0xabc'),
        addEthereumPrefix: false,
      );

      expect(repo.payload, '0x616263'); // utf8 'abc' hex, no prefix
    });

    test('honors explicit encoding/hash overrides', () async {
      final repo = _CapturingSigningRepository();
      final useCase = SignMessageUseCase(repo);

      await useCase.call(
        message: 'hello',
        walletAccount:
            _account(v1AddressFormat.address_format_cosmos, 'cosmos1'),
        encoding: v1PayloadEncoding.payload_encoding_text_utf8,
        hashFunction: v1HashFunction.hash_function_sha256,
      );

      expect(repo.encoding, v1PayloadEncoding.payload_encoding_text_utf8);
      expect(repo.hashFunction, v1HashFunction.hash_function_sha256);
      expect(repo.payload, 'hello');
    });
  });
}
