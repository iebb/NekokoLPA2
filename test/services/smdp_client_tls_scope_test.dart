import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/services/smdp_client.dart';

void main() {
  test(
    'an ES9+ request leaves certificate checks on for other clients',
    () async {
      expect(HttpOverrides.current, isNull);

      // Nothing listens on port 1, so the request fails; what matters is what
      // making it leaves behind.
      await expectLater(
        SmdpClient.post(
          smdpAddress: '127.0.0.1:1',
          endpoint: 'gsma/rsp2/es9plus/initiateAuthentication',
          bodyData: const {},
        ),
        throwsA(anything),
      );

      expect(HttpOverrides.current, isNull);
    },
  );
}
