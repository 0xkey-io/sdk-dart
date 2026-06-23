import 'package:zeroxkey_http/zeroxkey_http.dart' show ZeroXKeyClient;

import '../../auth/auth_result.dart';
import '../../auth/passkey_auth_provider.dart';

class LoginWithPasskeyUseCase {
  final PasskeyAuthProvider _passkey;

  LoginWithPasskeyUseCase(this._passkey);

  Future<AuthResult> call({
    required ZeroXKeyClient client,
    required String publicKey,
    String? organizationId,
    String? expirationSeconds,
    bool? invalidateExisting,
  }) {
    return _passkey.loginWithPasskey(
      client: client,
      publicKey: publicKey,
      organizationId: organizationId,
      expirationSeconds: expirationSeconds,
      invalidateExisting: invalidateExisting,
    );
  }
}
