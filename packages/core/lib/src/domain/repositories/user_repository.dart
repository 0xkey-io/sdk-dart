import 'package:zeroxkey_http/zeroxkey_http.dart' show v1User;

/// Read access to user profile data.
abstract class UserRepository {
  /// Fetches a user by id within [organizationId]; returns `null` if absent.
  Future<v1User?> fetchUser({
    required String organizationId,
    required String userId,
  });
}
