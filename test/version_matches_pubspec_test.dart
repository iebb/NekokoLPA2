import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/version.dart';

/// lib/version.dart is what the app displays, and pubspec.yaml is what the
/// release tag and the platform build numbers come from. They are maintained
/// by hand in two places (bump.sh writes both), so nothing stops a release
/// going out tagged one version and reporting another -- which is what
/// happened when 2.2.0 shipped still displaying 2.1.10.
void main() {
  test('the displayed version matches pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final declared = RegExp(
      r'^version:\s*(\S+)\+(\S+)\s*$',
      multiLine: true,
    ).firstMatch(pubspec);

    expect(
      declared,
      isNotNull,
      reason: 'pubspec.yaml must declare "version: <name>+<build>"',
    );

    expect(
      kAppVersion,
      declared!.group(1),
      reason:
          'lib/version.dart is stale; run ./bump.sh rather than editing '
          'pubspec.yaml alone',
    );
    expect(
      kAppBuildNumber,
      declared.group(2),
      reason: 'lib/version.dart build number is stale; run ./bump.sh',
    );
  });
}
