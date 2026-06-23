/// Strategy interface for authentication flows.
abstract class AuthProvider {
  /// Human-readable provider id (e.g. `otp`, `oauth`, `passkey`).
  String get name;
}
