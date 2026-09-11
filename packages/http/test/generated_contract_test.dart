import 'dart:io';

import 'package:test/test.dart';
import 'package:zeroxkey_http/__generated__/models.dart';
import 'package:zeroxkey_http/__generated__/public_api.client.dart';
import 'package:zeroxkey_http/base.dart';

const frozenOpenApiSha256 =
    '5434f36777abe0672c53e8c0b5b1938147de78a235ddb938f5877b616e6644ad'; // gitleaks:allow

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
    expect(pin['services_commit']?.length, 40);
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
