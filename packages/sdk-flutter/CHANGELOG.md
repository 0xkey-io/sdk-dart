# Changelog

## 0.1.1 - Security
- Default the hosted OAuth pages to `https://oauth-origin.0xkey.io` and
  `https://oauth-redirect.0xkey.io/` instead of `oauth-origin.0xkey.com` and
  `oauth-redirect.0xkey.com`, a domain 0xkey does not own. Without an Auth
  Proxy `oauthRedirectUrl` or an explicit `originUri`, Google and Apple sign-in
  used those hosts. The fallback provider callback is now
  `https://oauth-redirect.0xkey.io/?scheme=<appScheme>`. Nothing else changes.

## 0.1.0 - Initial Release
- High-level Flutter SDK (`ZeroXKeyProvider`, Auth Proxy, OTP, Passkey, wallets).
- Thin presentation layer over `zeroxkey_core`.
