import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/services/update_feed.dart';

void main() {
  const cert = 'c47350c7ba682b34a3e584a0d58463ea42b1ad73';
  const vendor = 'd1c0f48b370e74d4ea4770ed4c3cd70a3198d31f';
  Map<String, dynamic> release(int build, [List<String>? signatures]) => {
    'build': build,
    'signatures': signatures ?? [cert],
  };

  test('normal Open never selects the rooted or vendor Android APK', () {
    final result = UpdateFeed.selectAndroid(
      {
        'open-rooted-$cert': release(700),
        'std-$cert': release(800),
        'open-$cert': release(601),
      },
      variant: 'open',
      signatures: [cert],
      currentBuild: 600,
    );
    expect(result?['build'], 601);
  });

  test('rooted Open stays on its own channel', () {
    final result = UpdateFeed.selectAndroid(
      {
        'open-rooted-$cert': release(601),
        'open-$cert': release(700),
        'privileged-$cert': release(800),
      },
      variant: 'open-rooted',
      signatures: [cert],
      currentBuild: 600,
    );
    expect(result?['build'], 601);
  });

  test(
    'Community accepts old feeds without crossing into rooted or vendor APKs',
    () {
      final result = UpdateFeed.selectAndroid(
        {
          'open-$cert': release(601),
          'community-$cert': release(602),
          'community-rooted-$cert': release(900),
          'std-$cert': release(950),
        },
        variant: 'community',
        signatures: [cert],
        currentBuild: 600,
      );
      expect(result?['build'], 602);
    },
  );

  test('legacy Open identities accept Community feeds', () {
    for (final entry in {
      'open': 'community',
      'open-rooted': 'community-rooted',
    }.entries) {
      expect(
        UpdateFeed.selectAndroid(
          {'${entry.value}-$cert': release(601)},
          variant: entry.key,
          signatures: [cert],
          currentBuild: 600,
        )?['build'],
        601,
      );
    }
  });

  test('Android rejects a newer APK signed by another certificate', () {
    final result = UpdateFeed.selectAndroid(
      {
        'open-$cert': [
          release(601),
          release(900, [vendor]),
        ],
      },
      variant: 'open',
      signatures: [cert.toUpperCase()],
      currentBuild: 600,
    );
    expect(result?['build'], 601);
  });

  test('Open rejects unrestricted and malformed Android entries', () {
    final result = UpdateFeed.selectAndroid(
      {'open': release(700, []), 'open-unverified': release(800)},
      variant: 'open',
      signatures: [cert],
      currentBuild: 600,
    );
    expect(result, isNull);
  });

  test('Android does not offer the installed or older build', () {
    final result = UpdateFeed.selectAndroid(
      {'open-$cert': release(600)},
      variant: 'open',
      signatures: [cert],
      currentBuild: 600,
    );
    expect(result, isNull);
  });

  test('standard and multi-certificate legacy feeds still work', () {
    final result = UpdateFeed.selectAndroid(
      {
        'multi-$cert-$vendor': release(601, [cert, vendor]),
      },
      variant: 'multi',
      signatures: [vendor],
      currentBuild: 600,
    );
    expect(result?['build'], 601);
  });

  test('lineage experiment does not select a normal multi-signer APK', () {
    expect(
      UpdateFeed.selectAndroid(
        {
          'multi-$cert-$vendor': release(700, [cert, vendor]),
        },
        variant: 'lineage',
        signatures: [cert, vendor],
        currentBuild: 600,
      ),
      isNull,
    );
  });

  test('Open desktop cannot fall back to the standard distribution', () {
    expect(
      UpdateFeed.selectDesktop(
        {'std': release(700)},
        variant: 'open',
        currentBuild: 600,
      ),
      isNull,
    );
  });

  test('legacy store desktop identity maps to the Open channel', () {
    final result = UpdateFeed.selectDesktop(
      {'open': release(601), 'std': release(900)},
      variant: 'store',
      currentBuild: 600,
    );
    expect(result?['build'], 601);
  });

  test('standard desktop fallback remains compatible', () {
    final result = UpdateFeed.selectDesktop(
      {'std': release(601)},
      variant: 'sekiu',
      currentBuild: 600,
    );
    expect(result?['build'], 601);
  });

  test('desktop does not offer a downgrade', () {
    expect(
      UpdateFeed.selectDesktop(
        {'open': release(600)},
        variant: 'open',
        currentBuild: 600,
      ),
      isNull,
    );
  });
}
