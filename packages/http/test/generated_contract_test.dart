import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:test/test.dart';
import 'package:zeroxkey_http/__generated__/models.dart';
import 'package:zeroxkey_http/__generated__/public_api.client.dart';
import 'package:zeroxkey_http/base.dart';

const frozenOpenApiSha256 =
    'b42fcfa9a9480c2d4148038b8d9112559132b11727c7f839e05cb2782e3350e2'; // gitleaks:allow
const frozenServicesCommit = '096c1fec26bed3b3f8104b473b35903db76760bb';

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
    for (final line
        in File('lib/swagger/contract-pin.yaml').readAsStringSync().split('\n')) {
      final match = RegExp(r'^(\w+):\s*"([^"]+)"').firstMatch(line);
      if (match != null) {
        pin[match.group(1)!] = match.group(2)!;
      }
    }
    expect(pin['openapi_sha256'], frozenOpenApiSha256);
    expect(pin['services_commit'], frozenServicesCommit);
    final swagger = File('lib/swagger/public_api.swagger.json').readAsBytesSync();
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

  test('generated client exposes getMfaStatus', () {
    final client = ZeroXKeyClient(
      config: THttpConfig(baseUrl: 'https://api.0xkey.io'),
      stamper: _MockStamper(),
    );
    expect(client.getMfaStatus, isA<Function>());
  });
}
