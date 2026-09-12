# ZeroXKey Attested Stamper

This package generates Turnkey-compatible attested identity stamps for
ZeroXKey requests. It supports P-256 OIDC and verification-token schemes and
signs the exact request body with a caller-provided or generated P-256 key.

## Usage

```dart
import 'package:zeroxkey_attested_stamper/zeroxkey_attested_stamper.dart';

final stamper = AttestedStamper(
  identity: '<verification token>',
  scheme: AttestedScheme.p256VerificationToken,
  signer: P256AttestedKey.generate(),
);

final stamp = await stamper.stamp('{"organizationId":"org-id"}');
```

The returned stamp uses the `X-Stamp-Attested` header. Treat the identity
token and private signing key as secrets; the stamper does not include either
value in its string representation.
