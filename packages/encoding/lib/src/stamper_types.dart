/// Represents a stamp header name/value pair attached to a signed request.
class TStamp {
  final String stampHeaderName;
  final String stampHeaderValue;

  TStamp({
    required this.stampHeaderName,
    required this.stampHeaderValue,
  });
}

/// Interface for request stampers used by [ZeroXKeyClient] and stamper packages.
///
/// Implementations include API key stamping (`zeroxkey_api_key_stamper`) and
/// passkey stamping (`zeroxkey_passkey_stamper`).
abstract class TStamper {
  Future<TStamp> stamp(String input);
}
