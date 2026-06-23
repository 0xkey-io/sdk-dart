# Changelog

## 0.1.0 - Initial Release

Initial 0xkey release of the Dart/Flutter SDK.

- Rebrand packages to `zeroxkey_*` and classes to `ZeroXKey*`
- Sync Public API spec from `repos/services`
- Add `0xkey_hpke` HPKE schedule for enclave interoperability
- Default API hosts: `api.0xkey.io`, `authproxy.0xkey.io`
- Layered architecture: `zeroxkey_core` (pure Dart) + `zeroxkey_sdk_flutter` (presentation)
