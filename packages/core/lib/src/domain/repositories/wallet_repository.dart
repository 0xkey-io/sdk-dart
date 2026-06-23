import 'package:zeroxkey_http/zeroxkey_http.dart'
    show v1Activity, v1WalletAccountParams;

import '../entities/wallet_entity.dart';

/// Wallet lifecycle and read access.
///
/// Implementations own the wire interaction and bundle encryption; session
/// state and UI refresh remain a presentation concern.
abstract class WalletRepository {
  /// Lists wallets (with accounts) for [organizationId].
  Future<List<WalletEntity>> fetchWallets({required String organizationId});

  /// Creates a new wallet; returns the raw activity for status inspection.
  Future<v1Activity> createWallet({
    required String walletName,
    required List<v1WalletAccountParams> accounts,
    int? mnemonicLength,
  });

  /// Imports a wallet from [mnemonic], HPKE-sealing it to the enclave import
  /// bundle. Returns the raw activity.
  Future<v1Activity> importWallet({
    required String mnemonic,
    required String walletName,
    required List<v1WalletAccountParams> accounts,
    required String userId,
    required String organizationId,
    String? dangerouslyOverrideSignerPublicKey,
  });

  /// Exports and decrypts a wallet's mnemonic/key material.
  Future<String> exportWallet({
    required String walletId,
    required String organizationId,
    String? dangerouslyOverrideSignerPublicKey,
    bool returnMnemonic,
  });
}
