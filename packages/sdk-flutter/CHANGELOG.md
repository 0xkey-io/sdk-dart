# Changelog

## 0.1.1
- Delegate OTP/OAuth/Passkey and session flows to `zeroxkey_core` use cases.
- Add `HiveSessionStore` and OAuth redirect handler adapters over core ports.
- Public API surface unchanged (signatures preserved).

## 0.1.0 - Initial Release
- High-level Flutter SDK (`ZeroXKeyProvider`, Auth Proxy, OTP, Passkey, wallets).
- Thin presentation layer over `zeroxkey_core`.
