import 'package:test/test.dart';
import 'package:zeroxkey_core/zeroxkey_core.dart';
import 'package:zeroxkey_http/zeroxkey_http.dart'
    show externaldatav1Timestamp, v1User, v1WalletAccount;

void main() {
  group('UserMapper', () {
    test('maps wire user to entity', () {
      final mapper = UserMapper();
      final ts = externaldatav1Timestamp(seconds: '1', nanos: '0');
      final wire = v1User(
        userId: 'u1',
        userName: 'alice',
        userEmail: 'a@b.c',
        userTags: const [],
        apiKeys: const [],
        authenticators: const [],
        oauthProviders: const [],
        createdAt: ts,
        updatedAt: ts,
      );

      final entity = mapper.fromWire(wire);
      expect(entity, isNotNull);
      expect(entity!.user.userId, 'u1');
    });
  });

  group('WalletMapper', () {
    test('maps wire accounts to wallet entity', () {
      final mapper = WalletMapper();
      final accounts = <v1WalletAccount>[];

      final entity = mapper.fromWire(
        id: 'w1',
        name: 'main',
        accounts: accounts,
      );

      expect(entity.id, 'w1');
      expect(entity.name, 'main');
      expect(entity.accounts, accounts);
    });
  });
}
