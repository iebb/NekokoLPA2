import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nlpa2/adapter/ble/red_ble_adapter.dart';
import 'package:nlpa2/adapter/ccid/ccid_adapter.dart';
import 'package:nlpa2/adapter/euicc_adapter.dart';
import 'package:nlpa2/vowifi/vowifi_page.dart';
import 'package:nlpa2/vowifi/apple_dialer.dart';
import 'package:nlpa2/vowifi/vowifi_service.dart';
import 'package:nlpa2/vowifi/notifications.dart';
import 'package:nlpa2/theme/app_theme.dart';
import 'package:nlpa2/settings/app_settings.dart';

class _PageService extends VoWifiService {
  _PageService(Adapter adapter, Reader reader, {super.notifications})
    : super(
        adapter: adapter,
        reader: reader,
        channel: MethodChannel('test/page/${reader.id}'),
      );

  @override
  Future<void> loadMessages() async {}

  final actions = <String>[];
  int stopCalls = 0;
  bool sessionActive = false;
  @override
  bool get active => sessionActive;

  @override
  Future<void> stop({bool suspended = false}) async {
    stopCalls++;
  }

  void updateStatus(Map<String, dynamic> value) {
    status = value;
    notifyListeners();
  }

  void receiveCall() {
    status = {
      'registered': true,
      'call_ready': true,
      'call': {
        'direction': 'incoming',
        'state': 'incoming',
        'peer': '+441234567890',
      },
    };
    notifyListeners();
  }

  @override
  Future<Map<String, dynamic>> command(
    String action, [
    Map<String, dynamic> arguments = const {},
  ]) async {
    actions.add(action);
    return {};
  }
}

class _PendingNotifications implements VoWifiNotifications {
  final permission = Completer<bool>();
  int requests = 0;

  @override
  Future<bool> requestPermission() {
    requests++;
    return permission.future;
  }

  @override
  Future<void> showIncoming({
    required int messageId,
    required String lineKey,
  }) async {}
}

class _PermissionPageService extends _PageService {
  _PermissionPageService(
    super.adapter,
    super.reader, {
    required super.notifications,
  });
  int starts = 0;

  @override
  Future<void> start(Map<String, dynamic> configuration) async {
    starts++;
  }
}

void main() {
  testWidgets(
    'connection checking disables outgoing entries but keeps Stop available',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final adapter = RedBleAdapter();
      final reader = Reader(id: 'checking-ui', name: 'Reader', source: adapter);
      final service = _PageService(adapter, reader)..sessionActive = true;
      service.updateStatus({
        'phase': 'ready',
        'registered': true,
        'call_ready': true,
        'messaging_ready': true,
        'checking_connection': true,
      });
      Widget page({int section = 0, bool communicationOnly = false}) =>
          MaterialApp(
            locale: const Locale('zh'),
            supportedLocales: const [Locale('zh'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: VoWifiPage(
              key: ValueKey(section),
              adapter: adapter,
              reader: reader,
              service: service,
              initialSection: section,
              initialPeer: '888',
              communicationOnly: communicationOnly,
            ),
          );
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();
      expect(find.text('Checking connection…'), findsWidgets);
      final stop = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Stop Wi-Fi calling'),
      );
      expect(stop.onPressed, isNotNull);
      await tester.pumpWidget(page(section: 1, communicationOnly: true));
      await tester.pumpAndSettle();
      expect(find.text('Checking connection…'), findsOneWidget);
      expect(
        tester.widget<AppleDialer>(find.byType(AppleDialer)).onCall,
        isNull,
      );
      await tester.pumpWidget(page(section: 2, communicationOnly: true));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('vowifi-message-composer')),
        'Hello',
      );
      await tester.pump();
      expect(find.text('Checking connection…'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is IconButton && widget.tooltip == 'Send SMS',
              ),
            )
            .onPressed,
        isNull,
      );
      expect(service.actions, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      service.sessionActive = false;
      service.dispose();
    },
  );

  testWidgets(
    'Connect proceeds after optional permission timeout and observes late failure',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final adapter = RedBleAdapter();
      final reader = Reader(
        id: 'permission-timeout',
        name: 'Reader',
        source: adapter,
      );
      final notifications = _PendingNotifications();
      final service = _PermissionPageService(
        adapter,
        reader,
        notifications: notifications,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: VoWifiPage(
            adapter: adapter,
            reader: reader,
            service: service,
            connectionOnly: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final connect = find.widgetWithText(FilledButton, 'Connect');
      await tester.ensureVisible(connect);
      await tester.tap(connect);
      await tester.pump();
      expect(notifications.requests, 1);
      expect(service.starts, 0);
      await tester.pump(const Duration(seconds: 4));
      expect(service.starts, 0);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(service.starts, 1);
      expect(notifications.requests, 1);
      notifications.permission.completeError(
        StateError('Late optional notification failure'),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(service.error, isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      service.dispose();
    },
  );

  testWidgets('SMS editor stays above keyboard and uses the current line', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    AppSettings().setRevealSensitiveProfileData(true);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final adapter = RedBleAdapter();
    final reader = Reader(id: 'sms-editor', name: 'Reader', source: adapter);
    final service = _PageService(adapter, reader);
    await tester.pumpWidget(
      MaterialApp(
        home: VoWifiPage(
          adapter: adapter,
          reader: reader,
          service: service,
          initialSection: 2,
          initialPeer: '888',
          communicationOnly: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final editor = find.byKey(const ValueKey('vowifi-message-composer'));
    expect(editor, findsOneWidget);
    expect(tester.getBottomRight(editor).dy, lessThanOrEqualTo(544));
    expect(find.byTooltip('Send SMS'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'communication destination hides connection setup and accepts a number',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final adapter = RedBleAdapter();
      final reader = Reader(id: 'direct-dial', name: 'Reader', source: adapter);
      final service = _PageService(adapter, reader);
      await tester.pumpWidget(
        MaterialApp(
          home: VoWifiPage(
            adapter: adapter,
            reader: reader,
            service: service,
            initialSection: 1,
            initialPeer: '1033',
            communicationOnly: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Connection settings'), findsNothing);
      expect(find.byKey(const ValueKey('vowifi-section')), findsNothing);
      expect(
        tester.widget<AppleDialer>(find.byType(AppleDialer)).number,
        '1033',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      expect(service.stopCalls, 0);
    },
  );
  testWidgets('backgrounding does not explicitly stop an idle VoWiFi session', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final ble = RedBleAdapter();
    final reader = Reader(id: 'background', name: 'ESTKme-RED', source: ble);
    final service = _PageService(ble, reader)..busy = true;

    await tester.pumpWidget(
      MaterialApp(
        home: VoWifiPage(adapter: ble, reader: reader, service: service),
      ),
    );
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(service.stopCalls, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(
      service.stopCalls,
      0,
      reason: 'Removing the view must preserve the session',
    );
  });

  testWidgets(
    'English localization fallback explains proxy host and connection errors',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final ble = RedBleAdapter();
      final reader = Reader(id: 'ble', name: 'ESTKme-RED', source: ble);
      final service = _PageService(
        ble,
        reader,
      )..error = 'The native Wi-Fi calling engine is unavailable in this build';
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: const [Locale('zh'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: VoWifiPage(adapter: ble, reader: reader, service: service),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Wi-Fi calling'), findsOneWidget);
      expect(find.text('Bluetooth SIM reader'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Connect'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.device_phone_portrait), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.creditcard), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.shield), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.phone), findsWidgets);
      expect(find.byIcon(CupertinoIcons.checkmark_seal), findsOneWidget);
      expect(
        find.text(
          'The native Wi-Fi calling engine is unavailable in this build',
        ),
        findsOneWidget,
      );
      tester
          .widget<TextButton>(find.byKey(const ValueKey('vowifi-action-1')))
          .onPressed!();
      await tester.pumpAndSettle();
      final phoneFieldFinder = find.byKey(
        const ValueKey('vowifi-phone-number'),
      );
      await tester.ensureVisible(phoneFieldFinder);
      final phoneField = tester.widget<TextField>(phoneFieldFinder);
      await tester.tap(phoneFieldFinder);
      await tester.pump();
      expect(find.byTooltip('Hide keyboard'), findsOneWidget);
      expect(phoneField.focusNode?.hasFocus, isTrue);
      await tester.tap(find.byTooltip('Hide keyboard'));
      await tester.pump();
      expect(phoneField.focusNode?.hasFocus, isFalse);
      tester
          .widget<TextButton>(find.byKey(const ValueKey('vowifi-action-0')))
          .onPressed!();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Connection settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Connection settings'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          '127.0.0.1 refers to this iPhone, not your Mac. To use a proxy on your Mac, enter its LAN address.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());

      final usb = CcidAdapter();
      final usbReader = Reader(id: 'usb', name: 'USB reader', source: usb);
      await tester.pumpWidget(
        MaterialApp(
          home: VoWifiPage(
            adapter: usb,
            reader: usbReader,
            service: _PageService(usb, usbReader),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Wi-Fi calling'), findsOneWidget);
      expect(find.text('USB CCID smart-card reader'), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'incoming controls remain above scrolled content and dismiss keypad',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      AppSettings().setRevealSensitiveProfileData(true);
      final ble = RedBleAdapter();
      final reader = Reader(id: 'incoming', name: 'ESTKme-RED', source: ble);
      final service = _PageService(ble, reader);
      await tester.pumpWidget(
        MaterialApp(
          home: VoWifiPage(adapter: ble, reader: reader, service: service),
        ),
      );
      await tester.pumpAndSettle();
      tester
          .widget<TextButton>(find.byKey(const ValueKey('vowifi-action-2')))
          .onPressed!();
      await tester.pumpAndSettle();
      final number = find.byKey(const ValueKey('vowifi-phone-number'));
      await tester.ensureVisible(number);
      await tester.pumpAndSettle();
      await tester.tap(number);
      await tester.pump();
      expect(tester.widget<TextField>(number).focusNode!.hasFocus, isTrue);
      service.receiveCall();
      service.updateStatus({...service.status, 'checking_connection': true});
      await tester.pumpAndSettle();
      expect(find.text('Incoming call'), findsOneWidget);
      expect(find.text('+441234567890'), findsOneWidget);
      expect(find.text('Answer').hitTestable(), findsOneWidget);
      expect(find.text('Decline').hitTestable(), findsOneWidget);
      expect(tester.widget<TextField>(number).focusNode!.hasFocus, isFalse);
      await tester.tap(find.text('Answer'));
      await tester.pumpAndSettle();
      expect(service.actions, ['answer']);
      await tester.tap(find.text('Decline'));
      await tester.pumpAndSettle();
      expect(service.actions, ['answer', 'reject']);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('active call keypad button reveals usable DTMF controls', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final ble = RedBleAdapter();
    final reader = Reader(id: 'keypad', name: 'ESTKme-RED', source: ble);
    final service = _PageService(ble, reader)
      ..status = {
        'registered': true,
        'call': {
          'direction': 'outgoing',
          'state': 'active',
          'peer': '888',
          'media_ready': true,
        },
        'checking_connection': true,
      };
    await tester.pumpWidget(
      MaterialApp(
        home: VoWifiPage(adapter: ble, reader: reader, service: service),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Keypad'));
    await tester.pumpAndSettle();
    expect(find.text('1').hitTestable(), findsOneWidget);
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    expect(service.actions, ['dtmf']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('registered number is copyable and disappears on disconnect', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    AppSettings().setRevealSensitiveProfileData(true);
    final ble = RedBleAdapter();
    final reader = Reader(id: 'own-number', name: 'ESTKme-RED', source: ble);
    final service = _PageService(ble, reader);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: VoWifiPage(adapter: ble, reader: reader, service: service),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('vowifi-own-number')), findsNothing);

    service.updateStatus({
      'phase': 'ready',
      'registered': true,
      'msisdn': '+441212345678',
      'mcc': '234',
      'mnc': '33',
    });
    await tester.pumpAndSettle();
    expect(find.text('🇬🇧 +441212345678'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('vowifi-copy-own-number')));
    await tester.pump();
    expect(copied, '+441212345678');
    expect(find.byTooltip('Copied'), findsOneWidget);
    expect(
      tester
          .widget<SelectableText>(
            find.byKey(const ValueKey('vowifi-own-number')),
          )
          .style
          ?.color,
      CupertinoColors.systemGreen,
    );

    await tester.tap(find.byKey(const ValueKey('vowifi-privacy-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('🇬🇧 +••••••••••••'), findsOneWidget);
    expect(find.byKey(const ValueKey('vowifi-copy-own-number')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('vowifi-privacy-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('🇬🇧 +441212345678'), findsOneWidget);
    service.updateStatus({
      'phase': 'stopped',
      'registered': false,
      'msisdn': '+441212345678',
    });
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('vowifi-own-number')), findsNothing);
    expect(find.text('🇬🇧 +441212345678'), findsNothing);

    service.updateStatus({
      'phase': 'ready',
      'registered': true,
      'msisdn': '0000000000',
    });
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('vowifi-own-number-unavailable')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('vowifi-own-number')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'narrow Apple layout handles large text across all sections',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      AppSettings().setRevealSensitiveProfileData(true);
      await tester.binding.setSurfaceSize(const Size(320, 690));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final ble = RedBleAdapter();
      final reader = Reader(
        id: 'large-text',
        name: 'ESTKme-RED Bluetooth reader',
        source: ble,
      );
      final service = _PageService(ble, reader)
        ..status = {
          'phase': 'ready',
          'registered': true,
          'msisdn': '+441212345678',
        };
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme(false),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.8)),
            child: child!,
          ),
          home: VoWifiPage(adapter: ble, reader: reader, service: service),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('🇬🇧 +441212345678'), findsOneWidget);
      expect(tester.takeException(), isNull);
      for (final section in [1, 2, 0]) {
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('vowifi-section')),
          180,
          scrollable: find
              .descendant(
                of: find.byKey(const ValueKey('vowifi-content')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        tester
            .widget<TextButton>(find.byKey(ValueKey('vowifi-action-$section')))
            .onPressed!();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      service.receiveCall();
      await tester.pumpAndSettle();
      expect(find.text('Incoming call'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Answer'));
      await tester.tap(find.text('Answer'));
      await tester.pumpAndSettle();
      expect(service.actions, ['answer']);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
