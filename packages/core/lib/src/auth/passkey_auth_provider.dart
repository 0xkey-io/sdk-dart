import 'package:zeroxkey_http/zeroxkey_http.dart';

import '../domain/repositories/passkey_repository.dart';
import '../errors/exceptions.dart';
import 'auth_provider.dart';
import 'auth_result.dart';

/// Passkey stamp-login orchestration.
///
/// The passkey-stamped [ZeroXKeyClient] is built by the presentation layer
/// (rpId/org specific) and passed in per call.
class PasskeyAuthProvider implements AuthProvider {
  final PasskeyRepository _passkey;

  PasskeyAuthProvider({required PasskeyRepository passkey})
      : _passkey = passkey;

  @override
  String get name => 'passkey';

  Future<AuthResult> loginWithPasskey({
    required ZeroXKeyClient client,
    required String publicKey,
    String? organizationId,
    String? expirationSeconds,
    bool? invalidateExisting,
  }) async {
    try {
      final res = await _passkey.stampLogin(
        client: client,
        body: TStampLoginBody(
          organizationId: organizationId,
          publicKey: publicKey,
          expirationSeconds: expirationSeconds,
          invalidateExisting: invalidateExisting,
        ),
      );
      final session = res.result?.session;
      if (session == null || session.isEmpty) {
        throw const AuthException(
            'No session returned from passkey stampLogin');
      }
      return AuthResult(sessionToken: session, action: AuthAction.login);
    } catch (e) {
      if (e is ZeroXKeyException) rethrow;
      throw AuthException('Passkey login failed: $e');
    }
  }
}
