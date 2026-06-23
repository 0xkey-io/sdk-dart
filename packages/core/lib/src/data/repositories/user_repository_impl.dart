import 'package:zeroxkey_http/zeroxkey_http.dart'
    show ZeroXKeyClient, TGetUserBody, v1User;

import '../../domain/repositories/user_repository.dart';
import '../../network/api_error_mapper.dart';

/// [UserRepository] backed by the generated [ZeroXKeyClient].
///
/// The client is resolved lazily so the repository always targets the session's
/// currently-active client/stamper.
class UserRepositoryImpl implements UserRepository {
  final ZeroXKeyClient Function() _client;
  final ApiErrorMapper _errors;

  UserRepositoryImpl(
    this._client, {
    ApiErrorMapper errors = const ApiErrorMapper(),
  }) : _errors = errors;

  @override
  Future<v1User?> fetchUser({
    required String organizationId,
    required String userId,
  }) {
    return _errors.guard(() async {
      final res = await _client().getUser(
        input: TGetUserBody(organizationId: organizationId, userId: userId),
      );
      return res.user;
    });
  }
}
