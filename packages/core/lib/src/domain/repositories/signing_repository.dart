import 'package:zeroxkey_http/zeroxkey_http.dart'
    show
        v1PayloadEncoding,
        v1HashFunction,
        v1SignRawPayloadResult,
        v1SignTransactionResult,
        v1TransactionType;

/// Remote signing operations executed by the enclave.
abstract class SigningRepository {
  Future<v1SignRawPayloadResult> signRawPayload({
    required String signWith,
    required String payload,
    required v1PayloadEncoding encoding,
    required v1HashFunction hashFunction,
  });

  Future<v1SignTransactionResult> signTransaction({
    required String signWith,
    required String unsignedTransaction,
    required v1TransactionType type,
  });
}
