/// Domain view of a policy (id + intent fingerprint).
class PolicyEntity {
  final String policyId;
  final String policyName;
  final String signatureFingerprint;

  const PolicyEntity({
    required this.policyId,
    required this.policyName,
    required this.signatureFingerprint,
  });
}
