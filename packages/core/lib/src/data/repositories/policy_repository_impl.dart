import 'package:zeroxkey_http/zeroxkey_http.dart';

import '../../network/api_error_mapper.dart';
import '../../domain/repositories/policy_repository.dart';

class PolicyRepositoryImpl implements PolicyRepository {
  final ZeroXKeyClient Function() _client;
  final ApiErrorMapper _errors;

  PolicyRepositoryImpl(
    this._client, {
    ApiErrorMapper errors = const ApiErrorMapper(),
  }) : _errors = errors;

  @override
  Future<TGetPoliciesResponse> getPolicies({
    required String organizationId,
  }) {
    return _errors.guard(() => _client().getPolicies(
          input: TGetPoliciesBody(organizationId: organizationId),
        ));
  }

  @override
  Future<TCreatePoliciesResponse> createPolicies({
    required TCreatePoliciesBody body,
  }) {
    return _errors.guard(() => _client().createPolicies(input: body));
  }
}
