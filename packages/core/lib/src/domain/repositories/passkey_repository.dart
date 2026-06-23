import 'package:zeroxkey_http/zeroxkey_http.dart';

/// Passkey stamp-login wire access.
///
/// Unlike other repositories, the passkey flow uses a transient,
/// passkey-stamped [ZeroXKeyClient] constructed per call (rpId/org specific),
/// so the client is injected per request instead of via a session resolver.
abstract class PasskeyRepository {
  Future<TStampLoginResponse> stampLogin({
    required ZeroXKeyClient client,
    required TStampLoginBody body,
  });
}
