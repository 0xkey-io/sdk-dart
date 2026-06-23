import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'package:zeroxkey_encoding/zeroxkey_encoding.dart';
import 'package:zeroxkey_api_key_stamper/zeroxkey_api_key_stamper.dart';

export 'package:zeroxkey_encoding/zeroxkey_encoding.dart' show TStamp, TStamper;

/// Seals and stamps the request body with your ZeroXKey API credentials.
///
/// You can either:
/// - Before calling [sealAndStampRequestBody], initialize with your ZeroXKey API credentials via init(...).
/// - Or, provide [apiPublicKey] and [apiPrivateKey] here as arguments.
Future<Map<String, String>> sealAndStampRequestBody({
  required Map<String, dynamic> body,
  String? apiPublicKey,
  String? apiPrivateKey,
}) async {
  // Fallback to configuration if keys are not provided
  apiPublicKey ??= getConfig().apiPublicKey;
  apiPrivateKey ??= getConfig().apiPrivateKey;

  final String sealedBody = stableStringify(body);

  final String signature = await signWithApiKey(
    apiPublicKey,
    apiPrivateKey,
    sealedBody,
  );

  final String sealedStamp = stableStringify({
    'publicKey': apiPublicKey,
    'scheme': 'SIGNATURE_SCHEME_TK_API_P256',
    'signature': signature,
  });

  final String xStamp = stringToBase64urlString(sealedStamp);

  return {
    'sealedBody': sealedBody,
    'xStamp': xStamp,
  };
}

class THttpConfig {
  final String baseUrl;
  final String? organizationId;
  final String? authProxyBaseUrl;
  final String? authProxyConfigId;

  THttpConfig({
    required this.baseUrl,
    this.organizationId,
    this.authProxyBaseUrl,
    this.authProxyConfigId,
  });
}

/// Minimal, transport-agnostic representation of an HTTP response.
///
/// Decoupling the generated client from a concrete HTTP stack lets higher
/// layers (e.g. `zeroxkey_core`) decorate the transport with tracing, retry,
/// and timeout policies without touching protocol handling.
class HttpResponse {
  final int statusCode;
  final String body;

  const HttpResponse({required this.statusCode, required this.body});
}

/// Abstraction over the network layer used by [ZeroXKeyClient].
///
/// Implementations only perform the wire I/O; request stamping, envelope
/// construction, status validation and JSON decoding remain the caller's
/// responsibility so the API protocol stays identical regardless of transport.
abstract class HttpTransport {
  /// Sends a POST request and returns the raw status code and body.
  ///
  /// [timeout] is advisory; implementations should honor it when supported and
  /// surface timeouts as exceptions rather than swallowing them.
  Future<HttpResponse> post({
    required String url,
    required String body,
    required Map<String, String> headers,
    Duration? timeout,
  });
}

/// Default [HttpTransport] backed by `package:http`.
///
/// Sets a JSON content type unless the caller overrides it and applies a
/// bounded default timeout so a stalled connection cannot hang indefinitely.
class DefaultHttpTransport implements HttpTransport {
  final Duration defaultTimeout;

  DefaultHttpTransport({this.defaultTimeout = const Duration(seconds: 30)});

  @override
  Future<HttpResponse> post({
    required String url,
    required String body,
    required Map<String, String> headers,
    Duration? timeout,
  }) async {
    final mergedHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...headers,
    };

    final response = await http
        .post(Uri.parse(url), headers: mergedHeaders, body: body)
        .timeout(timeout ?? defaultTimeout);

    return HttpResponse(statusCode: response.statusCode, body: response.body);
  }
}

/// Represents a signed request ready to be POSTed to ZeroXKey
class TSignedRequest {
  final String body;
  final TStamp stamp;
  final String url;

  TSignedRequest({
    required this.body,
    required this.stamp,
    required this.url,
  });
}

// Represents a stamp header name/value pair
// (defined in zeroxkey_encoding; re-exported above for backward compatibility)

class GrpcStatus {
  final String message;
  final int code;
  final List<dynamic>? details;

  GrpcStatus({
    required this.message,
    required this.code,
    this.details,
  });

  factory GrpcStatus.fromJson(Map<String, dynamic> json) {
    return GrpcStatus(
      message: json['message'] as String,
      code: json['code'] as int,
      details: json['details'] as List<dynamic>?, // This can be null
    );
  }
}

/// Interface to implement if you want to provide your own stampers for your [ZeroXKeyClient].
///
/// Currently, ZeroXKey provides two stampers:
/// - Applications signing requests with Passkeys or WebAuthn devices should use `@zeroxkey/webauthn-stamper`.
/// - Applications signing requests with API keys should use `@zeroxkey/api-key-stamper`.
// TStamper is defined in zeroxkey_encoding and re-exported above.

class ZeroXKeyRequestError implements Exception {
  final List<dynamic>? details;
  final int code;
  final String message;

  ZeroXKeyRequestError(GrpcStatus status)
      : details = status.details,
        code = status.code,
        message = _generateMessage(status);

  static String _generateMessage(GrpcStatus status) {
    var errorMessage = '0xkey error ${status.code}: ${status.message}';

    if (status.details != null) {
      errorMessage += ' (Details: ${jsonEncode(status.details)})';
    }

    return errorMessage;
  }

  @override
  String toString() => message;
}

/// Converts a [Map<String, dynamic>] into a JSON string representation.
///
/// Parameters:
/// - [input]: The [Map<String, dynamic>] to stringify.
///
/// Returns:
/// - A [String] containing the JSON representation of the input.
String stableStringify(Map<String, dynamic> input) {
  return jsonEncode(input);
}
