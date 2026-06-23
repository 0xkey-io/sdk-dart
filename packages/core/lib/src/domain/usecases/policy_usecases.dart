import 'package:zeroxkey_http/zeroxkey_http.dart';

import '../repositories/policy_repository.dart';

class FetchPoliciesUseCase {
  final PolicyRepository _policies;

  FetchPoliciesUseCase(this._policies);

  Future<TGetPoliciesResponse> call({required String organizationId}) {
    return _policies.getPolicies(organizationId: organizationId);
  }
}

class CreatePoliciesUseCase {
  final PolicyRepository _policies;

  CreatePoliciesUseCase(this._policies);

  Future<TCreatePoliciesResponse> call({required TCreatePoliciesBody body}) {
    return _policies.createPolicies(body: body);
  }
}
