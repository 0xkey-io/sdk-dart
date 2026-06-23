import 'package:zeroxkey_http/zeroxkey_http.dart';

import '../repositories/wallet_kit_config_repository.dart';

class FetchWalletKitConfigUseCase {
  final WalletKitConfigRepository _config;

  FetchWalletKitConfigUseCase(this._config);

  Future<ProxyTGetWalletKitConfigResponse> call() {
    return _config.fetchWalletKitConfig();
  }
}
