import 'package:zeroxkey_http/zeroxkey_http.dart'
    show
        v1AddressFormat,
        v1PayloadEncoding,
        v1HashFunction,
        v1SignRawPayloadResult,
        v1WalletAccount;

import '../../data/signing_codec.dart';
import '../repositories/signing_repository.dart';

/// Encapsulates the message-signing flow: resolve encoding/hash defaults from
/// the account's address format, optionally apply the EIP-191 prefix, encode the
/// payload, and delegate the raw signature to [SigningRepository].
class SignMessageUseCase {
  final SigningRepository _signing;

  const SignMessageUseCase(this._signing);

  Future<v1SignRawPayloadResult> call({
    required String message,
    required v1WalletAccount walletAccount,
    v1PayloadEncoding? encoding,
    v1HashFunction? hashFunction,
    bool? addEthereumPrefix,
  }) {
    final resolvedEncoding =
        encoding ?? SigningCodec.encodingFor(walletAccount.addressFormat);
    final resolvedHash =
        hashFunction ?? SigningCodec.hashFor(walletAccount.addressFormat);

    final isEthereum =
        walletAccount.addressFormat == v1AddressFormat.address_format_ethereum;

    var bytes = SigningCodec.toUtf8Bytes(message);
    if (isEthereum && (addEthereumPrefix ?? true)) {
      bytes = SigningCodec.applyEthereumPrefix(bytes);
    }

    final encoded = SigningCodec.encodeMessage(resolvedEncoding, bytes);

    return _signing.signRawPayload(
      signWith: walletAccount.address,
      payload: encoded,
      encoding: resolvedEncoding,
      hashFunction: resolvedHash,
    );
  }
}
