---
title: "Verify OTP target bundles against the signer enclave's signing key"
date: "2026-11-22"
packages:
  zeroxkey_crypto: "patch"
  zeroxkey_core: "patch"
  zeroxkey_sdk_flutter: "patch"
---

Email and SMS OTP verification failed against the production API before any
request was sent: `encryptOtpCodeToBundle` checked the `otp_init_v2` target
bundle against the production quorum *encryption* key (`0438c11a…`), but the
signer enclave signs that bundle with its quorum *signing* key (`046d10ba…`).
It now defaults to `PRODUCTION_SIGNER_SIGN_PUBLIC_KEY`, the key the other
bundle checks already use, and the misnamed internal alias
`PRODUCTION_TLS_FETCHER_SIGN_PUBLIC_KEY` is removed.

`BackendProvider.signerPublicKeyOverride` (and the new
`ZeroXKeyConfig.signerPublicKeyOverride` in the Flutter SDK) now also applies to
OTP verification, so apps pointed at a non-production deployment can supply
that deployment's signer key. Leave it unset for the production API.

OTP login is unchanged: it signs in through Auth Proxy `otp_login_v2` with a
client signature by the key bound to the verification token, and does not call
`stamp_login` with an Attested stamp, so it does not depend on whether the API
gateway accepts Attested stamps. The Session lifetime comes from the Auth Proxy
configuration, and an `authProxyConfigId` is required.
