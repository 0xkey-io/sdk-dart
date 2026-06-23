import 'package:zeroxkey_crypto/zeroxkey_crypto.dart'
    show encryptWalletToBundle, decryptExportBundle, generateP256KeyPair;
import 'package:zeroxkey_http/zeroxkey_http.dart'
    show
        ZeroXKeyClient,
        TGetWalletsBody,
        TGetWalletAccountsBody,
        TCreateWalletBody,
        TInitImportWalletBody,
        TImportWalletBody,
        TExportWalletBody,
        v1Activity,
        v1Pagination,
        v1WalletAccount,
        v1WalletAccountParams;

import '../../domain/entities/wallet_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../errors/exceptions.dart';
import '../../network/api_error_mapper.dart';

/// [WalletRepository] backed by the generated client plus the crypto package for
/// HPKE bundle sealing/opening. No session/UI state is touched here.
class WalletRepositoryImpl implements WalletRepository {
  static const int _pageLimit = 100;

  final ZeroXKeyClient Function() _client;
  final ApiErrorMapper _errors;

  WalletRepositoryImpl(
    this._client, {
    ApiErrorMapper errors = const ApiErrorMapper(),
  }) : _errors = errors;

  @override
  Future<List<WalletEntity>> fetchWallets({required String organizationId}) {
    return _errors.guard(() async {
      final client = _client();
      final walletsRes = await client.getWallets(
        input: TGetWalletsBody(organizationId: organizationId),
      );
      final accounts = await _fetchAllAccounts(organizationId);
      return walletsRes.wallets.map((wallet) {
        final walletAccounts = accounts
            .where((account) => account.walletId == wallet.walletId)
            .toList();
        return WalletEntity(
          id: wallet.walletId,
          name: wallet.walletName,
          accounts: walletAccounts,
        );
      }).toList();
    });
  }

  Future<List<v1WalletAccount>> _fetchAllAccounts(String organizationId) async {
    final client = _client();
    final all = <v1WalletAccount>[];
    String? cursor;
    var hasMore = false;
    do {
      final res = await client.getWalletAccounts(
        input: TGetWalletAccountsBody(
          organizationId: organizationId,
          paginationOptions:
              v1Pagination(limit: _pageLimit.toString(), after: cursor),
        ),
      );
      all.addAll(res.accounts);
      if (all.length == _pageLimit) {
        hasMore = true;
        cursor = all.last.walletAccountId;
      } else {
        hasMore = false;
      }
    } while (hasMore);
    return all;
  }

  @override
  Future<v1Activity> createWallet({
    required String walletName,
    required List<v1WalletAccountParams> accounts,
    int? mnemonicLength,
  }) {
    return _errors.guard(() async {
      final res = await _client().createWallet(
        input: TCreateWalletBody(
          accounts: accounts,
          walletName: walletName,
          mnemonicLength: mnemonicLength,
        ),
      );
      return res.activity;
    });
  }

  @override
  Future<v1Activity> importWallet({
    required String mnemonic,
    required String walletName,
    required List<v1WalletAccountParams> accounts,
    required String userId,
    required String organizationId,
    String? dangerouslyOverrideSignerPublicKey,
  }) {
    return _errors.guard(() async {
      final client = _client();
      final initRes = await client.initImportWallet(
          input: TInitImportWalletBody(userId: userId));
      final importBundle =
          initRes.activity.result?.initImportWalletResult?.importBundle;
      if (importBundle == null) {
        throw const SigningException('Failed to get import bundle');
      }

      final encryptedBundle = await encryptWalletToBundle(
        mnemonic: mnemonic,
        importBundle: importBundle,
        userId: userId,
        organizationId: organizationId,
        dangerouslyOverrideSignerPublicKey: dangerouslyOverrideSignerPublicKey,
      );

      final res = await client.importWallet(
        input: TImportWalletBody(
          userId: userId,
          walletName: walletName,
          encryptedBundle: encryptedBundle,
          accounts: accounts,
        ),
      );
      return res.activity;
    });
  }

  @override
  Future<String> exportWallet({
    required String walletId,
    required String organizationId,
    String? dangerouslyOverrideSignerPublicKey,
    bool returnMnemonic = true,
  }) {
    return _errors.guard(() async {
      final keyPair = await generateP256KeyPair();
      final res = await _client().exportWallet(
        input: TExportWalletBody(
          walletId: walletId,
          targetPublicKey: keyPair.publicKeyUncompressed,
        ),
      );
      final exportBundle =
          res.activity.result?.exportWalletResult?.exportBundle;
      if (exportBundle == null) {
        throw const SigningException('Export bundle not initialized');
      }
      return decryptExportBundle(
        exportBundle: exportBundle,
        embeddedKey: keyPair.privateKey,
        organizationId: organizationId,
        dangerouslyOverrideSignerPublicKey: dangerouslyOverrideSignerPublicKey,
        returnMnemonic: returnMnemonic,
      );
    });
  }
}
