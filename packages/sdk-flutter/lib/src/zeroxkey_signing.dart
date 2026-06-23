part of 'zeroxkey.dart';

extension SigningExtension on ZeroXKeyProvider {
  /// Signs a raw payload using the specified signing key and encoding parameters.
  ///
  /// Throws an [Exception] if the client or user is not initialized.
  ///
  /// [signWith] The key to sign with.
  /// [payload] The payload to sign.
  /// [encoding] The encoding of the payload.
  /// [hashFunction] The hash function to use.
  Future<v1SignRawPayloadResult> signRawPayload(
      {required String signWith,
      required String payload,
      required v1PayloadEncoding encoding,
      required v1HashFunction hashFunction}) async {
    if (session == null) {
      throw Exception("No active session found. Please log in first.");
    }

    return _container.signingRepository.signRawPayload(
      signWith: signWith,
      payload: payload,
      encoding: encoding,
      hashFunction: hashFunction,
    );
  }

  /// Signs a plaintext message using the specified wallet account.
  ///
  /// Automatically determines the payload encoding and hash function based on
  /// the wallet account's address format, unless explicitly overridden.
  /// Optionally applies the Ethereum signed message prefix before signing.
  /// If you need more control over the signing process, consider using [signRawPayload] directly from the client.
  ///
  /// Throws an [Exception] if there is no active session or if signing fails.
  ///
  /// [message] The UTF-8 plaintext message to sign.
  /// [walletAccount] The wallet account whose signing key will be used.
  /// [encoding] Optional override for the payload encoding. Defaults to the encoding associated with the wallet account's address format.
  /// [hashFunction] Optional override for the hash function. Defaults to the hash function associated with the wallet account's address format.
  /// [addEthereumPrefix] Whether to add the Ethereum message prefix before signing. Defaults to `true` when the address format is Ethereum.
  Future<v1SignRawPayloadResult> signMessage({
    required String message,
    required v1WalletAccount walletAccount,
    v1PayloadEncoding? encoding,
    v1HashFunction? hashFunction,
    bool? addEthereumPrefix,
  }) async {
    if (session == null) {
      throw Exception("No active session found. Please log in first.");
    }

    return _container.signMessageUseCase.call(
      message: message,
      walletAccount: walletAccount,
      encoding: encoding,
      hashFunction: hashFunction,
      addEthereumPrefix: addEthereumPrefix,
    );
  }

  /// Signs a message using a key pair stored in secure storage.
  ///
  /// This function signs the provided message string with the private key identified by [publicKey].
  /// The message is SHA-256 hashed internally before signing (ECDSA P-256).
  /// Returns a compact hex signature (r || s) suitable for use as a client signature.
  /// The key pair must already exist in secure storage (e.g., created via [createApiKeyPair]).
  ///
  /// [message] The message string to sign.
  /// [publicKey] The public key identifying which key pair to sign with.
  /// Returns the compact hex signature string.
  /// Throws an [Exception] if signing fails.
  Future<String> signWithApiKey({
    required String message,
    required String publicKey,
  }) async {
    final previousPublicKey = secureStorageStamper.publicKey;
    try {
      secureStorageStamper.setPublicKey(publicKey);
      final signature = await secureStorageStamper.sign(
        message,
        format: SignatureFormat.raw,
      );
      if (signature.isEmpty) {
        throw Exception('Failed to sign with API key: empty signature');
      }
      return signature;
    } finally {
      secureStorageStamper.setPublicKey(previousPublicKey ?? '');
    }
  }

  /// Signs a transaction using the specified signing key and transaction parameters.
  ///
  /// Throws an [Exception] if the client or user is not initialized.
  ///
  /// [signWith] The key to sign with.
  /// [unsignedTransaction] The unsigned transaction to sign.
  /// [type] The type of the transaction from the [TransactionType] enum.
  Future<v1SignTransactionResult> signTransaction(
      {required String signWith,
      required String unsignedTransaction,
      required v1TransactionType type}) async {
    if (session == null) {
      throw Exception("No active session found. Please log in first.");
    }

    return _container.signingRepository.signTransaction(
      signWith: signWith,
      unsignedTransaction: unsignedTransaction,
      type: type,
    );
  }
}
