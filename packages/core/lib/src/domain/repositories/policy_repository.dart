import 'package:zeroxkey_http/zeroxkey_http.dart';

abstract class PolicyRepository {
  Future<TGetPoliciesResponse> getPolicies({
    required String organizationId,
  });

  Future<TCreatePoliciesResponse> createPolicies({
    required TCreatePoliciesBody body,
  });
}
