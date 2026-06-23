# zeroxkey_core

Platform-agnostic core for the [ZeroXKey](https://0xkey.io) SDK. Pure Dart
(no Flutter imports) so it can be unit-tested in isolation and reused across
runtimes.

## Layers

| Layer | Responsibility |
|-------|----------------|
| **errors** | `ZeroXKeyException` hierarchy; `ApiErrorMapper` translates wire `ZeroXKeyRequestError` |
| **config / provider** | `ZeroXKeyConfiguration`, `ResolvedRuntimeConfig`, `BackendProvider` |
| **network** | `MiddlewareHttpTransport` (trace id, retry, timeout) |
| **ports** | `Signer`, `KeyStore`, `SessionStore`, `OAuthRedirectHandler` |
| **auth** | `OtpAuthProvider`, `OAuthAuthProvider`, `PasskeyAuthProvider` → `AuthResult` |
| **domain** | entities, repository interfaces, use cases |
| **data** | repository implementations, DTO mappers, `ClientSignatureCodec` |
| **di** | `ZeroXKeyContainer` hand-written composition root |

## Usage

Most apps depend on `zeroxkey_sdk_flutter` only. To assemble the graph directly:

```dart
import 'package:zeroxkey_core/zeroxkey_core.dart';
import 'package:zeroxkey_http/zeroxkey_http.dart';

final container = ZeroXKeyContainer(
  configuration: const ZeroXKeyConfiguration(
    backend: ZeroXKeyBackendProvider(),
  ),
  clientResolver: () => myActiveZeroXKeyClient,
  signer: mySigner,
  keyStore: myKeyStore,
);

final client = ZeroXKeyClient(
  config: THttpConfig(baseUrl: 'https://api.0xkey.io'),
  stamper: mySigner,
  transport: container.transport,
);

await container.initOtpUseCase.call(
  contact: 'user@example.com',
  otpType: 'OTP_TYPE_EMAIL',
);
```

## Extending Signer / KeyStore

Implement `Signer` (stamping + client signatures) and `KeyStore` (key lifecycle)
in your runtime adapter. `zeroxkey_sdk_flutter` ships `SecureStorageStamper` /
`SecureStorageKeyStore` (Flutter Secure Storage) and passkey stamping via
`PasskeyStamper`.

## Tests

```bash
dart test
```
