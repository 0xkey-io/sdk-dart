import 'package:zeroxkey_http/zeroxkey_http.dart' show v1WalletAccount;

/// Domain representation of a wallet and its accounts.
///
/// Decouples consumers from the generated wire DTOs while still exposing the
/// protocol-stable [v1WalletAccount] entries (which carry address/format data
/// the UI needs verbatim).
class WalletEntity {
  final String id;
  final String name;
  final List<v1WalletAccount> accounts;

  const WalletEntity({
    required this.id,
    required this.name,
    required this.accounts,
  });
}
