import 'package:test/test.dart';
import 'package:zeroxkey_http/zeroxkey_http.dart';

/// Mock-recorded payloads for the OTP → session → GetWhoami → SignRawPayload
/// happy path. Staging is not required for CI; these fixtures validate that
/// generated models match the auth proxy / public API response shapes.
void main() {
  group('OTP auth proxy smoke fixtures', () {
    test('boot config → init OTP → verify → login session', () {
      final config = ProxyTGetWalletKitConfigResponse.fromJson({
        'enabledProviders': ['email', 'passkey'],
        'sessionExpirationSeconds': '900',
        'organizationId': '11111111-2222-3333-4444-555555555555',
        'otpLength': '6',
        'otpAlphanumeric': false,
      });
      expect(config.enabledProviders, contains('email'));

      final initOtp = ProxyTInitOtpResponse.fromJson({
        'otpId': 'otp-id-smoke-fixture',
      });
      expect(initOtp.otpId, isNotEmpty);

      final verifyOtp = ProxyTVerifyOtpResponse.fromJson({
        'verificationToken': 'verification-token-smoke-fixture',
      });
      expect(verifyOtp.verificationToken, isNotEmpty);

      final login = ProxyTOtpLoginV2Response.fromJson({
        'session':
            'eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.smoke-session.smoke-signature',
      });
      expect(login.session, contains('.'));
    });
  });

  group('Public API smoke fixtures', () {
    test('GetWhoami response deserializes', () {
      final whoami = TGetWhoamiResponse.fromJson({
        'organizationId': '11111111-2222-3333-4444-555555555555',
        'organizationName': 'Smoke Org',
        'userId': '22222222-3333-4444-5555-666666666666',
        'username': 'smoke-user@example.com',
      });

      expect(whoami.organizationName, 'Smoke Org');
      expect(whoami.username, contains('@'));
    });

    test('SignRawPayload completed activity deserializes', () {
      final signResponse = TSignRawPayloadResponse.fromJson({
        'activity': {
          'id': 'act-smoke-001',
          'organizationId': '11111111-2222-3333-4444-555555555555',
          'status': 'ACTIVITY_STATUS_COMPLETED',
          'type': 'ACTIVITY_TYPE_SIGN_RAW_PAYLOAD_V2',
          'intent': <String, dynamic>{},
          'votes': [],
          'fingerprint': 'fp-smoke',
          'canApprove': false,
          'canReject': false,
          'createdAt': {'seconds': '1718000000', 'nanos': '0'},
          'updatedAt': {'seconds': '1718000000', 'nanos': '0'},
          'timestampMs': '1718000000000',
        },
        'result': {
          'r': '0xabc',
          's': '0xdef',
          'v': '27',
        },
      });

      expect(signResponse.activity.status,
          v1ActivityStatus.activity_status_completed);
      expect(signResponse.result?.r, '0xabc');
    });
  });
}
