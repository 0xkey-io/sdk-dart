import 'package:zeroxkey_http/zeroxkey_http.dart'
    show
        ZeroXKeyClient,
        TSignRawPayloadBody,
        TSignTransactionBody,
        v1PayloadEncoding,
        v1HashFunction,
        v1SignRawPayloadResult,
        v1SignTransactionResult,
        v1TransactionType;

import '../../domain/repositories/signing_repository.dart';
import '../../errors/exceptions.dart';
import '../../network/api_error_mapper.dart';

/// [SigningRepository] backed by the generated client. Maps missing results to
/// [SigningException] so callers never receive a silent `null`.
class SigningRepositoryImpl implements SigningRepository {
  final ZeroXKeyClient Function() _client;
  final ApiErrorMapper _errors;

  SigningRepositoryImpl(
    this._client, {
    ApiErrorMapper errors = const ApiErrorMapper(),
  }) : _errors = errors;

  @override
  Future<v1SignRawPayloadResult> signRawPayload({
    required String signWith,
    required String payload,
    required v1PayloadEncoding encoding,
    required v1HashFunction hashFunction,
  }) {
    return _errors.guard(() async {
      final res = await _client().signRawPayload(
        input: TSignRawPayloadBody(
          signWith: signWith,
          payload: payload,
          encoding: encoding,
          hashFunction: hashFunction,
        ),
      );
      final result = res.activity.result?.signRawPayloadResult;
      if (result == null || res.activity.failure != null) {
        throw const SigningException('Failed to sign raw payload');
      }
      return result;
    });
  }

  @override
  Future<v1SignTransactionResult> signTransaction({
    required String signWith,
    required String unsignedTransaction,
    required v1TransactionType type,
  }) {
    return _errors.guard(() async {
      final res = await _client().signTransaction(
        input: TSignTransactionBody(
          signWith: signWith,
          unsignedTransaction: unsignedTransaction,
          type: type,
        ),
      );
      final result = res.activity.result?.signTransactionResult;
      if (result == null) {
        throw const SigningException('Failed to sign transaction');
      }
      return result;
    });
  }
}
