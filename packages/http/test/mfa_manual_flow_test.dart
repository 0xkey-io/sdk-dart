import 'dart:convert';

import 'package:test/test.dart';
import 'package:zeroxkey_http/zeroxkey_http.dart';

class _RecordingStamper implements TStamper {
  final List<String> bodies = [];
  @override
  Future<TStamp> stamp(String input) async {
    bodies.add(input);
    return TStamp(stampHeaderName: 'X-Stamp', stampHeaderValue: 'stamp');
  }
}

void main() {
  test('MFA status and approval remain two explicit fingerprint-bound calls',
      () async {
    final stamper = _RecordingStamper();
    final client = ZeroXKeyClient(
      config:
          THttpConfig(baseUrl: 'https://api.0xkey.io', organizationId: 'org'),
      stamper: stamper,
    );
    final status = await client.stampGetMfaStatus(
      input: const TGetMfaStatusBody(activityId: 'activity', userId: 'user'),
    );
    final approval = await client.stampApproveActivity(
      input: const TApproveActivityBody(fingerprint: 'sha256:target'),
    );

    expect(status.url, 'https://api.0xkey.io/public/v1/query/get_mfa_status');
    expect(
        jsonDecode(status.body), {'activityId': 'activity', 'userId': 'user'});
    expect(
        approval.url, 'https://api.0xkey.io/public/v1/submit/approve_activity');
    final approvalBody = jsonDecode(approval.body) as Map<String, dynamic>;
    expect(approvalBody['type'], 'ACTIVITY_TYPE_APPROVE_ACTIVITY');
    expect(approvalBody['parameters'], {'fingerprint': 'sha256:target'});
    expect(stamper.bodies, hasLength(2));
  });
}
