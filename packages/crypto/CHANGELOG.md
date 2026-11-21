# Changelog

## 0.1.1 - Fix
- `encryptOtpCodeToBundle` now verifies the OTP encryption target bundle
  against the signer enclave's quorum signing key
  (`PRODUCTION_SIGNER_SIGN_PUBLIC_KEY`, `046d10ba…`). It used the production
  quorum encryption key (`0438c11a…`), so every production bundle was rejected
  with `Expected signer key 0438… does not match signer key from bundle: 046d…`
  and email/SMS OTP verification could not succeed. Pass
  `dangerouslyOverrideSignerPublicKey` only for non-production deployments.

## 0.1.0 - Initial Release
- Cryptographic utilities including 0xkey-native HPKE and OTP bundle encryption.
