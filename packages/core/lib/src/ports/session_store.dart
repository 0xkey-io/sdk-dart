import '../domain/entities/session_entity.dart';

/// Persists session metadata (Hive in Flutter; in-memory for tests).
abstract class SessionStore {
  Future<void> storeSessionJwt(String jwt, {String? sessionKey});

  Future<SessionEntity?> getSession(String sessionKey);

  Future<String?> getActiveSessionKey();

  Future<void> setActiveSessionKey(String sessionKey);

  Future<List<String>> listSessionKeys();

  Future<void> clearSession(String sessionKey);

  Future<void> clearAllSessions();
}
