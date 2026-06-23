import '../../domain/entities/user_entity.dart';
import '../../domain/entities/wallet_entity.dart';
import 'package:zeroxkey_http/zeroxkey_http.dart' show v1User, v1WalletAccount;

class UserMapper {
  const UserMapper();

  UserEntity? fromWire(v1User? user) => user == null ? null : UserEntity(user);
}

class WalletMapper {
  const WalletMapper();

  WalletEntity fromWire({
    required String id,
    required String name,
    required List<v1WalletAccount> accounts,
  }) {
    return WalletEntity(id: id, name: name, accounts: accounts);
  }
}
