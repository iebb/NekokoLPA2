import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:nlpa2/adapter/euicc_adapter.dart';
import 'package:nlpa2/models/euicc_profile.dart';
import 'package:nlpa2/services/local_notification_service.dart';
import 'package:nlpa2/services/vowifi_sim_service.dart';
import 'package:nlpa2/services/vowifi_sms_service.dart';
import 'package:nlpa2/settings/app_settings.dart';
import 'package:nlpa2/vowifi_sms/vowifi_sms_plugin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final notificationCalls = <MethodCall>[];

  setUpAll(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    IOSFlutterLocalNotificationsPlugin.registerWith();
    messenger.setMockMethodCallHandler(channel, (call) async {
      notificationCalls.add(call);
      switch (call.method) {
        case 'initialize':
          return true;
        case 'show':
          return null;
        case 'requestPermissions':
          return true;
        default:
          return null;
      }
    });
  });

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    notificationCalls.clear();
    final settings = AppSettings();
    await settings.setVowifiEnabled(false);
    await settings.setVowifiAutoRenew(false);
  });

  tearDownAll(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
    channel.setMethodCallHandler(null);
  });

  group('VowifiAutoRenew settings and threshold', () {
    test(
      'vowifiAutoRenew requires vowifiEnabled to be active',
      () async {
        final settings = AppSettings();
        expect(settings.vowifiEnabled, isFalse);
        await settings.setVowifiAutoRenew(true);
        expect(settings.vowifiAutoRenew, isFalse);

        await settings.setVowifiEnabled(true, disclaimerAccepted: true);
        expect(settings.vowifiEnabled, isTrue);
        await settings.setVowifiAutoRenew(true);
        expect(settings.vowifiAutoRenew, isTrue);

        await settings.setVowifiEnabled(false);
        expect(settings.vowifiEnabled, isFalse);
        expect(settings.vowifiAutoRenew, isFalse);
      },
      skip: !AppSettings().vowifiAvailable,
    );

    test(
      'needsAutoRenew triggers only when less than 10% duration remains',
      () {
        final client = _MockVowifiSmsClient();
        final adapter = _MockAdapter();
        final reader = Reader(id: 'r1', name: 'Reader 1', source: adapter);
        final session = VowifiSessionInfo(
          id: 'r1:8901',
          adapter: adapter,
          reader: reader,
          readerId: reader.id,
          readerName: reader.name,
          iccid: '8901',
          profileName: 'Profile 1',
          client: client,
        );

        // Not registered
        expect(session.needsAutoRenew, isFalse);

        session.state = VowifiSmsConnectionState.registered;
        session.totalDuration = const Duration(seconds: 3600); // 1 hour

        // 50% remaining (1800s) -> false
        session.expiresAt = DateTime.now().add(const Duration(seconds: 1800));
        expect(session.needsAutoRenew, isFalse);

        // 15% remaining (540s) -> false
        session.expiresAt = DateTime.now().add(const Duration(seconds: 540));
        expect(session.needsAutoRenew, isFalse);

        // Just above 10% remaining -> false.
        session.expiresAt = DateTime.now().add(const Duration(seconds: 361));
        expect(session.needsAutoRenew, isFalse);

        // Just below 10% remaining -> true.
        session.expiresAt = DateTime.now().add(const Duration(seconds: 359));
        expect(session.needsAutoRenew, isTrue);

        // 5% remaining (180s) -> true
        session.expiresAt = DateTime.now().add(const Duration(seconds: 180));
        expect(session.needsAutoRenew, isTrue);

        // 0 remaining (expired) -> true
        session.expiresAt = DateTime.now().subtract(
          const Duration(seconds: 10),
        );
        expect(session.needsAutoRenew, isTrue);
      },
    );
  });

  group('VowifiSmsService auto-renewal execution', () {
    test(
      'auto-renew executes profile switch and re-auth when ICCID differs',
      () async {
        final settings = AppSettings();
        await settings.setVowifiEnabled(true, disclaimerAccepted: true);
        await settings.setVowifiAutoRenew(true);

        final simService = _TestVowifiSimService(initialIccid: '8901');
        _MockVowifiSmsClient? activeClient;
        final service = VowifiSmsService.forTesting(
          simService: simService,
          clientFactory:
              ({
                required adapter,
                required reader,
                required info,
                required config,
                onLog,
              }) {
                activeClient = _MockVowifiSmsClient(config: config);
                return activeClient!;
              },
        );

        final adapter = _MockAdapter();
        final reader = Reader(id: 'r1', name: 'Reader 1', source: adapter);
        final profile = EuiccProfile(iccid: '8901', enabled: true);

        final session = await service.connectCurrentCard(
          adapter: adapter,
          reader: reader,
          activeProfile: profile,
        );

        expect(session.state, VowifiSmsConnectionState.registered);
        expect(simService.enabledIccids, isEmpty);

        // Card is now switched to a different profile (8902)
        simService.currentIccid = '8902';

        // Set session to <10% remaining duration
        session.totalDuration = const Duration(seconds: 1000);
        session.expiresAt = DateTime.now().add(
          const Duration(seconds: 50),
        ); // 5%
        expect(session.needsAutoRenew, isTrue);

        // Trigger auto-renew check
        await service.checkAutoRenewForTesting();

        // Verify that auto-renew switched back to 8901 and re-authenticated
        expect(simService.enabledIccids, contains('8901'));
        expect(session.state, VowifiSmsConnectionState.registered);
        expect(session.lastInfo, contains('Profile switched'));
        expect(session.needsAutoRenew, isFalse);

        await service.disableAndDisconnect();
      },
      skip: !AppSettings().vowifiAvailable,
    );

    test(
      'auto-renew does not run when option is disabled',
      () async {
        final settings = AppSettings();
        await settings.setVowifiEnabled(true, disclaimerAccepted: true);
        await settings.setVowifiAutoRenew(false); // Disabled

        final simService = _TestVowifiSimService(initialIccid: '8901');
        final service = VowifiSmsService.forTesting(
          simService: simService,
          clientFactory:
              ({
                required adapter,
                required reader,
                required info,
                required config,
                onLog,
              }) => _MockVowifiSmsClient(config: config),
        );

        final adapter = _MockAdapter();
        final reader = Reader(id: 'r1', name: 'Reader 1', source: adapter);
        final session = await service.connectCurrentCard(
          adapter: adapter,
          reader: reader,
        );

        session.totalDuration = const Duration(seconds: 1000);
        session.expiresAt = DateTime.now().add(const Duration(seconds: 50));
        expect(session.needsAutoRenew, isTrue);

        simService.currentIccid = '8902';
        await service.checkAutoRenewForTesting();

        // Did not auto-switch
        expect(simService.enabledIccids, isEmpty);

        await service.disableAndDisconnect();
      },
      skip: !AppSettings().vowifiAvailable,
    );
  });

  group('Incoming SMS notifications', () {
    test(
      'inbound SMS displays system notification with sender and text',
      () async {
        final settings = AppSettings();
        await settings.setVowifiEnabled(true, disclaimerAccepted: true);

        final notifService = LocalNotificationService.forTesting();
        await notifService.init();

        final simService = _TestVowifiSimService(initialIccid: '8901000000');
        _MockVowifiSmsClient? activeClient;
        final service = VowifiSmsService.forTesting(
          simService: simService,
          notificationService: notifService,
          clientFactory:
              ({
                required adapter,
                required reader,
                required info,
                required config,
                onLog,
              }) {
                activeClient = _MockVowifiSmsClient(config: config);
                return activeClient!;
              },
        );

        final adapter = _MockAdapter();
        final reader = Reader(id: 'r1', name: 'Reader 1', source: adapter);
        final session = await service.connectCurrentCard(
          adapter: adapter,
          reader: reader,
        );

        notificationCalls.clear();

        // Emit inbound SMS event
        const testPeer = '+12025550199';
        const testBody = 'Your activation code is 123456';
        activeClient!.emitMessage(
          VowifiSmsMessage(
            direction: VowifiSmsDirection.inbound,
            text: testBody,
            timestamp: DateTime.fromMillisecondsSinceEpoch(0),
            peer: testPeer,
          ),
        );

        // Wait a tick for async notification call
        await Future<void>.delayed(const Duration(milliseconds: 200));

        expect(notificationCalls.map((c) => c.method), contains('show'));
        final showCall = notificationCalls.firstWhere(
          (c) => c.method == 'show',
        );
        final args = showCall.arguments as Map;
        // Default privacy redaction is active
        expect(args['title'], '+•••••••••••');
        expect(args['body'], '••••••');
        expect(
          args['platformSpecifics'],
          containsPair('subtitle', '••••••••••'),
        );
        final payload = jsonDecode(args['payload'] as String);
        expect(payload['type'], 'vowifi_sms');
        expect(payload['lineKey'], session.id);

        // When sensitive data is unmasked
        if (settings.isSensitiveDataMasked) {
          await settings.toggleSensitiveDataVisibility();
        }
        notificationCalls.clear();

        activeClient!.emitMessage(
          VowifiSmsMessage(
            direction: VowifiSmsDirection.inbound,
            text: testBody,
            timestamp: DateTime.fromMillisecondsSinceEpoch(0),
            peer: testPeer,
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        final unmaskedCall = notificationCalls.firstWhere(
          (c) => c.method == 'show',
        );
        final unmaskedArgs = unmaskedCall.arguments as Map;
        expect(unmaskedArgs['title'], testPeer);
        expect(unmaskedArgs['body'], testBody);

        await service.disableAndDisconnect();
      },
      skip: !AppSettings().vowifiAvailable,
    );

    test(
      'outbound SMS does not trigger system notification',
      () async {
        final settings = AppSettings();
        await settings.setVowifiEnabled(true, disclaimerAccepted: true);

        final notifService = LocalNotificationService.forTesting();
        await notifService.init();

        final simService = _TestVowifiSimService(initialIccid: '8901');
        _MockVowifiSmsClient? activeClient;
        final service = VowifiSmsService.forTesting(
          simService: simService,
          notificationService: notifService,
          clientFactory:
              ({
                required adapter,
                required reader,
                required info,
                required config,
                onLog,
              }) {
                activeClient = _MockVowifiSmsClient(config: config);
                return activeClient!;
              },
        );

        final adapter = _MockAdapter();
        final reader = Reader(id: 'r1', name: 'Reader 1', source: adapter);
        await service.connectCurrentCard(adapter: adapter, reader: reader);

        notificationCalls.clear();

        activeClient!.emitMessage(
          VowifiSmsMessage(
            direction: VowifiSmsDirection.outbound,
            text: 'Sent text',
            timestamp: DateTime.now(),
            peer: '+12025550199',
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(notificationCalls.where((c) => c.method == 'show'), isEmpty);

        await service.disableAndDisconnect();
      },
      skip: !AppSettings().vowifiAvailable,
    );
  });
}

class _TestVowifiSimService extends VowifiSimService {
  _TestVowifiSimService({required this.initialIccid})
    : currentIccid = initialIccid;

  final String initialIccid;
  String currentIccid;
  final List<String> enabledIccids = <String>[];

  @override
  Future<VowifiCardInfo> probe(
    Adapter adapter,
    Reader reader, {
    void Function(String line)? onLog,
  }) async {
    return VowifiCardInfo(
      iccid: currentIccid,
      imsi: '310260123456789',
      mncLength: 3,
      smsc: '+12025550123',
    );
  }

  @override
  Future<void> enableProfileBasic(
    Adapter adapter,
    Reader reader, {
    required String iccid,
  }) async {
    enabledIccids.add(iccid);
    currentIccid = iccid;
  }
}

class _MockVowifiSmsClient extends VowifiSmsClient {
  _MockVowifiSmsClient({super.config = const VowifiSmsConfig()});

  final StreamController<VowifiSmsEvent> _controller =
      StreamController<VowifiSmsEvent>.broadcast();

  @override
  Stream<VowifiSmsEvent> get events => _controller.stream;

  @override
  DateTime? get registeredUntil => DateTime.now().add(const Duration(hours: 1));

  @override
  Duration? get registeredDuration => const Duration(hours: 1);

  @override
  String get publicIdentity =>
      'sip:+12025550100@ims.mnc260.mcc310.3gppnetwork.org';

  @override
  List<String> get associatedIdentities => const [
    'sip:+12025550100@ims.mnc260.mcc310.3gppnetwork.org',
  ];

  @override
  String get preferredIdentity => '+12025550100';

  @override
  Future<void> connectAndRegister() async {}

  @override
  Future<void> refreshRegistration() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> sendTextSms(String to, String text) async {}

  void emitMessage(VowifiSmsMessage message) {
    _controller.add(VowifiSmsEvent.message(message));
  }
}

class _MockAdapter extends BaseAdapter {
  _MockAdapter() : super(Logger('_MockAdapter'));

  @override
  Future<List<Reader>> listReaders({bool force = false}) async => <Reader>[];

  @override
  Future<void> connect(Reader reader) async {
    updateConnectedReader(reader);
  }

  @override
  Future<void> disconnect() async {
    updateConnectedReader(null);
  }

  @override
  Future<void> reconnect() async {}

  @override
  Future<void> cleanupChannels() async {}

  @override
  Future<Channel> openChannel({List<String>? aids}) {
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> sendRawApdu(Uint8List apdu) async => Uint8List(0);

  @override
  Stream<EuiccPortState> get stateStream => const Stream.empty();

  @override
  bool get requiresRefresh => false;

  @override
  String? get lastAtr => null;
}
