import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:zeroxkey_core/zeroxkey_core.dart';
import 'package:zeroxkey_http/zeroxkey_http.dart';

const _authProxyBaseUrl = 'https://authproxy.example.test';
const _apiBaseUrl = 'https://api.example.test';
const _authProxyConfigId = 'auth-proxy-config-test';
const _clientPublicKey =
    '02a47b1d44ab3c7c5bd3e1d3c5e8b4b9d0f1e7a83a2bdd1f0c45e6a1f5f2a9c1b2';
const _organizationId = '00000000-0000-4000-8000-000000000001';

Map<String, dynamic> _fixture() => jsonDecode(
      File('../../testdata/otp-encryption-target-bundle.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;

String _verificationToken() {
  String part(Map<String, dynamic> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return [
    part({'alg': 'ES256', 'typ': 'JWT'}),
    part({
      'contact': 'user@example.com',
      'exp': 4102444800,
      'id': 'token-1',
      'public_key': _clientPublicKey,
      'verification_type': 'OTP_TYPE_EMAIL',
      'organization_id': _organizationId,
    }),
    'sig',
  ].join('.');
}

class _Request {
  final String url;
  final Map<String, String> headers;
  final Map<String, dynamic> body;

  _Request(this.url, this.headers, this.body);
}

/// Serves the Auth Proxy OTP routes and answers `stamp_login` the way a
/// gateway that cannot take Attested stamps does.
class _FakeTransport implements HttpTransport {
  final String bundle;
  final HttpResponse stampLoginResponse;
  final requests = <_Request>[];

  _FakeTransport({required this.bundle, required this.stampLoginResponse});

  @override
  Future<HttpResponse> post({
    required String url,
    required String body,
    required Map<String, String> headers,
    Duration? timeout,
  }) async {
    requests
        .add(_Request(url, headers, jsonDecode(body) as Map<String, dynamic>));
    if (url.endsWith('/stamp_login')) return stampLoginResponse;
    final route = url.replaceFirst(_authProxyBaseUrl, '');
    final json = switch (route) {
      '/v1/otp_init_v2' => {
          'otpId': 'otp-1',
          'otpEncryptionTargetBundle': bundle,
        },
      '/v1/otp_verify_v2' => {'verificationToken': _verificationToken()},
      '/v1/account' => {'organizationId': _organizationId},
      '/v1/otp_login_v2' => {'session': 'session-jwt'},
      _ => null,
    };
    if (json == null) {
      return const HttpResponse(
          statusCode: 404, body: '{"code":5,"message":"not found"}');
    }
    return HttpResponse(statusCode: 200, body: jsonEncode(json));
  }
}

class _NoopStamper implements TStamper {
  @override
  Future<TStamp> stamp(String payload) async =>
      TStamp(stampHeaderName: 'X-Stamp', stampHeaderValue: 'unused');
}

class _FakeSigner implements Signer {
  String? publicKey;

  @override
  void setPublicKey(String publicKey) => this.publicKey = publicKey;

  @override
  Future<String> sign(String message,
          {SignatureFormat format = SignatureFormat.raw}) async =>
      'aa' * 64;

  @override
  Future<TStamp> stamp(String payload) => throw UnimplementedError();
}

class _FakeKeyStore implements KeyStore {
  final keys = <String>[];

  @override
  Future<String> createKeyPair({
    String? externalPublicKey,
    String? externalPrivateKey,
    bool isCompressed = true,
  }) async {
    keys.add(_clientPublicKey);
    return _clientPublicKey;
  }

  @override
  Future<void> deleteKeyPair(String publicKey) async => keys.remove(publicKey);

  @override
  Future<List<String>> listKeyPairs() async => List.of(keys);
}

ZeroXKeyClient _client(HttpTransport transport) => ZeroXKeyClient(
      config: THttpConfig(
        baseUrl: _apiBaseUrl,
        authProxyBaseUrl: _authProxyBaseUrl,
        authProxyConfigId: _authProxyConfigId,
      ),
      stamper: _NoopStamper(),
      transport: transport,
    );

void main() {
  final stampLoginRefusals = {
    'gateway without Attested support (401, plain text)':
        const HttpResponse(statusCode: 401, body: 'Unauthorized'),
    'Attested stamps disabled (503 ATTESTED_STAMP_NOT_ENABLED)':
        const HttpResponse(
      statusCode: 503,
      body: '{"code":14,"message":"attested stamp not enabled",'
          '"details":[{"reason":"ATTESTED_STAMP_NOT_ENABLED"}]}',
    ),
  };

  for (final entry in stampLoginRefusals.entries) {
    test('email OTP login completes via otp_login_v2 when ${entry.key}',
        () async {
      final fixture = _fixture();
      final transport = _FakeTransport(
        bundle: fixture['bundle'] as String,
        stampLoginResponse: entry.value,
      );
      final signer = _FakeSigner();
      final provider = OtpAuthProvider(
        auth: AuthRepositoryImpl(() => _client(transport)),
        signer: signer,
        keyStore: _FakeKeyStore(),
        signerPublicKeyOverride: fixture['signerPublicKey'] as String,
      );

      final init = await provider.initOtp(
        contact: 'user@example.com',
        otpType: 'OTP_TYPE_EMAIL',
      );
      final result = await provider.loginOrSignUpWithOtp(
        otpId: init.otpId,
        otpCode: '123456',
        otpEncryptionTargetBundle: init.otpEncryptionTargetBundle,
        contact: 'user@example.com',
        otpFilterType: 'EMAIL',
      );

      expect(result.sessionToken, 'session-jwt');
      expect(result.action, AuthAction.login);
      final routes = transport.requests
          .map((r) => r.url.replaceFirst(_authProxyBaseUrl, ''))
          .toList();
      expect(routes, [
        '/v1/otp_init_v2',
        '/v1/otp_verify_v2',
        '/v1/account',
        '/v1/otp_login_v2',
      ]);
      for (final request in transport.requests) {
        expect(request.headers['X-Auth-Proxy-Config-ID'], _authProxyConfigId);
        expect(request.headers.containsKey('X-Stamp-Attested'), isFalse);
      }
      final login = transport.requests.last.body;
      expect(login['publicKey'], _clientPublicKey);
      expect(login['clientSignature']['publicKey'], _clientPublicKey);
      expect(login['clientSignature']['scheme'],
          'CLIENT_SIGNATURE_SCHEME_API_P256');
      expect(signer.publicKey, _clientPublicKey);
    });
  }

  test('verifyOtp checks the target bundle against the production signer key',
      () async {
    final fixture = _fixture();
    final transport = _FakeTransport(
      bundle: fixture['bundle'] as String,
      stampLoginResponse: const HttpResponse(statusCode: 500, body: ''),
    );
    final keyStore = _FakeKeyStore();
    final provider = OtpAuthProvider(
      auth: AuthRepositoryImpl(() => _client(transport)),
      signer: _FakeSigner(),
      keyStore: keyStore,
    );

    await expectLater(
      provider.verifyOtp(
        otpId: 'otp-1',
        otpCode: '123456',
        otpEncryptionTargetBundle: fixture['bundle'] as String,
      ),
      throwsA(isA<AuthException>()),
    );
    expect(transport.requests, isEmpty);
    expect(keyStore.keys, isEmpty);
  });

  test('container passes the backend signer override to OTP verification',
      () async {
    final fixture = _fixture();
    final transport = _FakeTransport(
      bundle: fixture['bundle'] as String,
      stampLoginResponse: const HttpResponse(statusCode: 500, body: ''),
    );
    final container = ZeroXKeyContainer(
      configuration: ZeroXKeyConfiguration(
        backend: ZeroXKeyBackendProvider(
          apiBaseUrl: _apiBaseUrl,
          authProxyBaseUrl: _authProxyBaseUrl,
          authProxyConfigId: _authProxyConfigId,
          signerPublicKeyOverride: fixture['signerPublicKey'] as String,
        ),
      ),
      clientResolver: () => _client(transport),
      signer: _FakeSigner(),
      keyStore: _FakeKeyStore(),
    );

    final verify = await container.verifyOtpUseCase.call(
      otpId: 'otp-1',
      otpCode: '123456',
      otpEncryptionTargetBundle: fixture['bundle'] as String,
    );

    expect(verify.verificationToken, _verificationToken());
    expect(verify.publicKey, _clientPublicKey);
  });
}
