import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/services/local_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];
  late LocalNotificationService service;
  TargetPlatform? previousTargetPlatform;
  bool? permissionResult = true;
  Map<String, Object?>? launchDetails;

  setUpAll(() async {
    previousTargetPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    IOSFlutterLocalNotificationsPlugin.registerWith();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'initialize':
          return true;
        case 'requestPermissions':
          return permissionResult;
        case 'getNotificationAppLaunchDetails':
          return launchDetails;
        case 'show':
          return null;
        default:
          throw StateError('Unexpected notification method: ${call.method}');
      }
    });
    service = LocalNotificationService.forTesting();
    await service.init();
  });

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    calls.clear();
    permissionResult = true;
    launchDetails = null;
  });

  tearDownAll(() {
    messenger.setMockMethodCallHandler(channel, null);
    channel.setMethodCallHandler(null);
    debugDefaultTargetPlatformOverride = previousTargetPlatform;
  });

  test('received SMS exposes no sender or body in the notification', () async {
    const lineKey = 'private-line-8901234567890123456';
    await service.showVoWifiSms(messageId: 42, lineKey: lineKey);

    expect(calls.map((call) => call.method), ['show']);
    final notification = calls.single.arguments as Map;
    expect(notification['title'], isNot(contains(lineKey)));
    expect(notification['body'], isNot(contains(lineKey)));
    expect(jsonDecode(notification['payload'] as String), {
      'type': 'vowifi_sms',
      'lineKey': lineKey,
    });
    expect(notification['id'], inInclusiveRange(0x40000000, 0x7fffffff));
    expect(
      notification['platformSpecifics'],
      containsPair('presentBadge', false),
    );
  });

  test(
    'showVoWifiSmsNotification delivers explicit sender, body, and payload',
    () async {
      const sender = '+12025550123';
      const body = 'Hello from carrier Wi-Fi';
      const lineKey = 'test-session-1';

      await service.showVoWifiSmsNotification(
        sender: sender,
        body: body,
        lineKey: lineKey,
        subtitle: 'Profile Alpha',
      );

      expect(calls.map((call) => call.method), ['show']);
      final notification = calls.single.arguments as Map;
      expect(notification['title'], sender);
      expect(notification['body'], body);
      expect(jsonDecode(notification['payload'] as String), {
        'type': 'vowifi_sms',
        'lineKey': lineKey,
      });
      expect(
        notification['platformSpecifics'],
        containsPair('subtitle', 'Profile Alpha'),
      );
    },
  );

  test('SMS notifications in a burst use distinct IDs', () async {
    await Future.wait([
      for (var index = 0; index < 3; index++)
        service.showVoWifiSmsNotification(sender: 'Sender', body: 'SMS $index'),
    ]);

    final ids = calls
        .where((call) => call.method == 'show')
        .map((call) => (call.arguments as Map)['id'])
        .toSet();
    expect(ids, hasLength(3));
  });

  for (final permission in <bool?>[true, false, null]) {
    test(
      'explicit permission request returns ${permission ?? false}',
      () async {
        permissionResult = permission;
        expect(await service.requestVoWifiSmsPermission(), permission ?? false);
        expect(calls.single.method, 'requestPermissions');
      },
    );
  }

  test('cold start returns only the notification routing payload', () async {
    final payload = jsonEncode({
      'type': 'vowifi_sms',
      'lineKey': 'second-line',
    });
    launchDetails = {
      'notificationLaunchedApp': true,
      'notificationResponse': {
        'notificationId': 42,
        'notificationResponseType': 0,
        'payload': payload,
      },
    };

    expect(await service.getLaunchPayload(), payload);
    expect(calls.single.method, 'getNotificationAppLaunchDetails');
  });

  test('ordinary launch ignores a stale response', () async {
    launchDetails = {
      'notificationLaunchedApp': false,
      'notificationResponse': {
        'notificationResponseType': 0,
        'payload': jsonEncode({'type': 'vowifi_sms', 'lineKey': 'stale'}),
      },
    };
    expect(await service.getLaunchPayload(), isNull);
  });
}
