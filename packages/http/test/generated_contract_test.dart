import 'dart:io';

import 'package:crypto/crypto.dart';

import 'package:test/test.dart';
import 'package:zeroxkey_http/__generated__/models.dart';
import 'package:zeroxkey_http/__generated__/public_api.client.dart';
import 'package:zeroxkey_http/base.dart';

const frozenOpenApiSha256 =
    'cca6a179db09bb9ea1d01deabd0b9e7122f4dbc1f27735efdcf433700aee42e2'; // gitleaks:allow
const frozenServicesCommit = '0eb6eb86a2ddb875552e97a33880d2c1c1eb4e4e';

class _MockStamper implements TStamper {
  @override
  Future<TStamp> stamp(String content) async {
    return TStamp(
      stampHeaderName: 'X-Stamp',
      stampHeaderValue: 'mock-stamp',
    );
  }
}

void main() {
  test('pin records the frozen services OpenAPI hash', () {
    final pin = <String, String>{};
    for (final line in File('lib/swagger/contract-pin.yaml')
        .readAsStringSync()
        .split('\n')) {
      final match = RegExp(r'^(\w+):\s*"([^"]+)"').firstMatch(line);
      if (match != null) {
        pin[match.group(1)!] = match.group(2)!;
      }
    }
    expect(pin['openapi_sha256'], frozenOpenApiSha256);
    expect(pin['services_commit'], frozenServicesCommit);
    final swagger =
        File('lib/swagger/public_api.swagger.json').readAsBytesSync();
    expect(sha256.convert(swagger).toString(), frozenOpenApiSha256);
  });

  test('generated status includes AUTHENTICATORS_NEEDED', () {
    expect(
      v1ActivityStatusToJson(
        v1ActivityStatus.activity_status_authenticators_needed,
      ),
      'ACTIVITY_STATUS_AUTHENTICATORS_NEEDED',
    );
  });

  test('unknown activity status degrades only to unspecified', () {
    expect(
      v1ActivityStatusFromJson('ACTIVITY_STATUS_ADDED_LATER'),
      v1ActivityStatus.activity_status_unspecified,
    );
  });

  test('generated client exposes getMfaStatus', () {
    final client = ZeroXKeyClient(
      config: THttpConfig(baseUrl: 'https://api.0xkey.io'),
      stamper: _MockStamper(),
    );
    expect(client.getMfaStatus, isA<Function>());
  });

  test('generated identity models match the Turnkey-aligned contract', () {
    final credential = externaldatav1Credential.fromJson({
      'publicKey': '04deadbeef',
      'type': 'CREDENTIAL_TYPE_LOGIN',
      'sessionProfileId': 'session-profile-1',
    });
    expect(credential.toJson()['sessionProfileId'], 'session-profile-1');

    final user = v1User.fromJson({
      'userId': 'user-1',
      'userName': 'Test User',
      'authenticators': <Object>[],
      'apiKeys': <Object>[],
      'userTags': <Object>[],
      'oauthProviders': <Object>[],
      'createdAt': {'seconds': '0', 'nanos': '0'},
      'updatedAt': {'seconds': '0', 'nanos': '0'},
      'mfaPolicies': <Object>[],
    });
    expect(user.toJson()['mfaPolicies'], isEmpty);

    expect(
      v1AuthenticationType.values.any(
        (value) => value.name == 'authentication_type_unspecified',
      ),
      isFalse,
    );
  });
}
