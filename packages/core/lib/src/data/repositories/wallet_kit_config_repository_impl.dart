import 'package:zeroxkey_http/zeroxkey_http.dart';

import '../../network/api_error_mapper.dart';
import '../../domain/repositories/wallet_kit_config_repository.dart';

class WalletKitConfigRepositoryImpl implements WalletKitConfigRepository {
  final ZeroXKeyClient Function() _client;
  final ApiErrorMapper _errors;

  WalletKitConfigRepositoryImpl(
    this._client, {
    ApiErrorMapper errors = const ApiErrorMapper(),
  }) : _errors = errors;

  @override
  Future<ProxyTGetWalletKitConfigResponse> fetchWalletKitConfig() {
    return _errors.guard(
      () => _client().proxyGetWalletKitConfig(
        input: ProxyTGetWalletKitConfigBody(),
      ),
    );
  }
}
