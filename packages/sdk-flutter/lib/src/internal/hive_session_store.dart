import 'package:zeroxkey_core/zeroxkey_core.dart';

import '../utils/types.dart';
import 'storage.dart';

/// Hive-backed [SessionStore] adapter (box `zeroxkey_sessions`, schema unchanged).
class HiveSessionStore implements SessionStore {
  const HiveSessionStore();

  static Future<void> ensureInitialized() => SessionStorageManager.init();

  @override
  Future<void> storeSessionJwt(String jwt, {String? sessionKey}) {
    return SessionStorageManager.storeSession(jwt, sessionKey: sessionKey);
  }

  @override
  Future<SessionEntity?> getSession(String sessionKey) async {
    final session = await SessionStorageManager.getSession(sessionKey);
    return session == null ? null : _toEntity(session, sessionKey);
  }

  @override
  Future<String?> getActiveSessionKey() {
    return SessionStorageManager.getActiveSessionKey();
  }

  @override
  Future<void> setActiveSessionKey(String sessionKey) {
    return SessionStorageManager.setActiveSessionKey(sessionKey);
  }

  @override
  Future<List<String>> listSessionKeys() {
    return SessionStorageManager.listSessionKeys();
  }

  @override
  Future<void> clearSession(String sessionKey) {
    return SessionStorageManager.clearSession(sessionKey);
  }

  @override
  Future<void> clearAllSessions() {
    return SessionStorageManager.clearAllSessions();
  }

  SessionEntity _toEntity(Session session, String sessionKey) {
    return SessionEntity(
      userId: session.userId,
      organizationId: session.organizationId,
      expiry: session.expiry,
      sessionType: session.sessionType,
      expirationSeconds: session.expirationSeconds,
      publicKey: session.publicKey,
      sessionKey: sessionKey,
    );
  }
}
