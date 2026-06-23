import 'package:zeroxkey_http/zeroxkey_http.dart';

import '../../domain/repositories/passkey_repository.dart';
import '../../network/api_error_mapper.dart';

class PasskeyRepositoryImpl implements PasskeyRepository {
  final ApiErrorMapper _errors;

  const PasskeyRepositoryImpl({ApiErrorMapper errors = const ApiErrorMapper()})
      : _errors = errors;

  @override
  Future<TStampLoginResponse> stampLogin({
    required ZeroXKeyClient client,
    required TStampLoginBody body,
  }) {
    return _errors.guard(() => client.stampLogin(input: body));
  }
}
