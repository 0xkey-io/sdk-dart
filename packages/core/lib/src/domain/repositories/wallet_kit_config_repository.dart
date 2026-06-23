import 'package:zeroxkey_http/zeroxkey_http.dart';

abstract class WalletKitConfigRepository {
  Future<ProxyTGetWalletKitConfigResponse> fetchWalletKitConfig();
}
