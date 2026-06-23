# ZeroXKey Api Stamper

This package contains functions to stamp a ZeroXKey request. It is meant to be used with ZeroXKey's [http package](/packages/http).

Example usage:

```dart
import 'package:zeroxkey_api_key_stamper/api_stamper.dart';
import 'package:zeroxkey_http/zeroxkey_http.dart';

// This stamper produces signatures using the API key pair passed in.
final stamper = ApiStamper(
  apiPublicKey: '...',
  apiPrivateKey: '...',
);

// The ZeroXKey client uses the passed in stamper to produce signed requests
// and sends them to ZeroXKey
final client = ZeroXKeyClient(
  config: THttpConfig(baseUrl: 'https://api.0xkey.io'),
  stamper: stamper,
);

// Now you can make authenticated requests!
final data = await client.getWhoami(
  input: TGetWhoamiRequest(organizationId: '<Your organization id>'),
);
```
