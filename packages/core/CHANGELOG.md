# Changelog

## 0.1.1
- Complete the clean architecture: auth provider strategies (OTP/OAuth/Passkey),
  domain repositories + data mappers, and end-to-end use cases.
- Expand `ZeroXKeyContainer` to wire repositories, providers, and use cases.

## 0.1.0 - Initial Release
- Pure-Dart core layer: domain entities, repositories, and use cases.
- Unified `ZeroXKeyException` error hierarchy with `ApiErrorMapper`.
- Network middleware: trace IDs, retry policy, timeout handling.
- `Signer` and `KeyStore` ports for pluggable signing strategies.
- Configurable `BackendProvider` and hand-written `ZeroXKeyContainer` (DI root).
