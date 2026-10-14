import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zeroxkey_sdk_flutter/src/utils/constants.dart';

void main() {
  test('hosted OAuth pages default to 0xkey.io', () {
    expect(ZEROXKEY_OAUTH_ORIGIN_URL, 'https://oauth-origin.0xkey.io');
    expect(ZEROXKEY_OAUTH_REDIRECT_URL, 'https://oauth-redirect.0xkey.io/');
  });

  test('ships no 0xkey.com host', () {
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => RegExp(r'0xkey\.com\b', caseSensitive: false)
            .hasMatch(file.readAsStringSync()))
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });
}
