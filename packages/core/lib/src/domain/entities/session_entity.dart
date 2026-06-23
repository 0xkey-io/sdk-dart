/// Domain view of an authenticated session (JWT-derived metadata).
class SessionEntity {
  final String userId;
  final String organizationId;
  final int expiry;
  final String sessionType;
  final String expirationSeconds;
  final String publicKey;
  final String sessionKey;

  const SessionEntity({
    required this.userId,
    required this.organizationId,
    required this.expiry,
    required this.sessionType,
    required this.expirationSeconds,
    required this.publicKey,
    required this.sessionKey,
  });
}
