import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:nlpa2/adapter/euicc_adapter.dart';
import 'package:nlpa2/logic/profile_manager.dart';
import 'package:nlpa2/models/asn1/rsp_definitions.g.dart';
import 'package:nlpa2/services/database_service.dart';
import 'package:nlpa2/services/notification_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const eid = '89049032000000000000000000000001';
PendingNotification notification(int event, {int seq = 7, int identity = 1}) =>
    PendingNotification.decode(
      PendingNotification(
        otherSignedNotification: OtherSignedNotification(
          tbsOtherNotification: NotificationMetadata(
            seqNumber: seq,
            profileManagementOperation: NotificationEvent(event),
            notificationAddress: 'smdp.example.test',
            iccid: Uint8List.fromList([identity]),
          ),
          euiccNotificationSignature: Uint8List.fromList([1, 2, 3]),
        ),
      ).encode(),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(sqfliteFfiInit);
  late Database db;
  late DatabaseService store;
  late NotificationService service;
  late _Manager manager;
  late int sends;
  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('''CREATE TABLE notifications (
      eid TEXT, iccid TEXT, seqNumber INTEGER, content TEXT, timestamp INTEGER,
      status INTEGER, responseCode INTEGER, responseContent TEXT,
      notificationServer TEXT, notificationType TEXT, deletePending INTEGER DEFAULT 0,
      PRIMARY KEY(eid, seqNumber, iccid))''');
    await DatabaseService.createNotificationDeliveryReceipts(db);
    store = DatabaseService.withDatabase(db);
    sends = 0;
    service = NotificationService.forTesting(
      database: store,
      sender: (n, address) async {
        sends++;
        return SendResult(true, 204, '');
      },
    );
    manager = _Manager(_Adapter());
  });
  tearDown(() async {
    await db.close();
  });

  Future<void> process({
    bool send = true,
    bool remove = false,
    Channel? channel,
  }) => service.processPendingNotifications(
    manager,
    channel,
    readerName: 'ble:test',
    eid: eid,
    autoSendInstall: send,
    autoRemoveInstall: remove,
    autoSendEnable: send,
    autoRemoveEnable: remove,
    deleteWithoutSendingEnable: false,
    autoSendDisable: send,
    autoRemoveDisable: remove,
    deleteWithoutSendingDisable: false,
    autoSendDelete: send,
    autoRemoveDelete: remove,
  );

  test(
    'enable and delete are sent without opening the notification page',
    () async {
      manager.card = [
        notification(NotificationEvent.notificationLocalEnable),
        notification(NotificationEvent.notificationLocalDelete, seq: 8),
      ];
      await process();
      expect(sends, 2);
      expect(service.pendingCount.value, 0);
      expect(service.currentNotifications.value, hasLength(2));
      expect(manager.removed, isEmpty);
    },
  );

  test(
    'deleting sent history preserves only a receipt and never sends again',
    () async {
      manager.card = [notification(NotificationEvent.notificationLocalDelete)];
      await process();
      final record = (await store.getAllNotifications()).single;
      await store.deleteNotification(
        record.eid,
        record.seqNumber,
        record.iccid,
      );
      expect(await store.getAllNotifications(), isEmpty);
      final receipt = (await db.query('notification_delivery_receipts')).single;
      expect(
        receipt.keys,
        unorderedEquals(['eid', 'seqNumber', 'iccid', 'contentHash']),
      );
      expect(receipt.values, isNot(contains(record.content)));
      await process();
      expect(sends, 1);
      expect(await store.getAllNotifications(), isEmpty);
      expect(service.currentNotifications.value, hasLength(1));
      expect(service.pendingCount.value, 0);
    },
  );

  test('a manually sent entry has a persistent delivery receipt', () async {
    final n = notification(NotificationEvent.notificationLocalDelete);
    expect(
      await service.sendNotification(n, 'smdp.example.test', eid: eid),
      isTrue,
    );
    expect(
      await service.sendNotification(n, 'smdp.example.test', eid: eid),
      isTrue,
    );
    expect(sends, 1);
    expect((await store.getAllNotifications()).single.status, 1);
  });

  test(
    'removing a retained notification is card-only and does not send',
    () async {
      manager.card = [notification(NotificationEvent.notificationLocalDelete)];
      await process();
      sends = 0;
      await service.removeFromCard(
        manager,
        _Channel(manager.adapter),
        7,
        expectedEid: eid,
      );
      expect(sends, 0);
      expect(manager.removed, [7]);
      expect(service.currentNotifications.value, isEmpty);
      expect(service.removedSeq.value, 7);
    },
  );

  test('an unsuccessful card removal is not reported as success', () async {
    manager.card = [notification(NotificationEvent.notificationLocalDelete)];
    manager.removalStatus =
        NotificationSentResponse_deleteNotificationStatus.undefinedError;
    await expectLater(
      service.removeFromCard(manager, _Channel(manager.adapter), 7),
      throwsStateError,
    );
    expect(service.removedSeq.value, isNull);
    expect(manager.card, hasLength(1));
  });

  test('an unconfirmed removal keeps the card entry visible', () async {
    manager.card = [notification(NotificationEvent.notificationLocalDelete)];
    manager.leaveOnCard = true;
    await expectLater(
      service.removeFromCard(manager, _Channel(manager.adapter), 7),
      throwsStateError,
    );
    expect(service.removedSeq.value, isNull);
  });

  test(
    'failed auto-removal retains retry state and the delivery receipt',
    () async {
      manager.card = [notification(NotificationEvent.notificationLocalDelete)];
      manager.removalStatus =
          NotificationSentResponse_deleteNotificationStatus.undefinedError;
      await process(remove: true);
      expect(sends, 1);
      expect((await store.getAllNotifications()).single.deletePending, 1);
      expect(service.currentNotifications.value, hasLength(1));
      expect(service.removedSeq.value, isNull);
      manager.removalStatus =
          NotificationSentResponse_deleteNotificationStatus.ok;
      await process(remove: true);
      expect(sends, 1);
      expect(service.currentNotifications.value, isEmpty);
    },
  );

  test('a failed send must not delete a notification', () async {
    service = NotificationService.forTesting(
      database: store,
      sender: (n, address) async {
        sends++;
        return SendResult(false, 503, 'Unavailable');
      },
    );
    manager.card = [notification(NotificationEvent.notificationLocalDelete)];
    await process(remove: true);
    expect(sends, 1);
    expect(manager.removed, isEmpty);
    expect(manager.card, hasLength(1));
    expect((await store.getAllNotifications()).single.status, 2);
    expect(await db.query('notification_delivery_receipts'), isEmpty);
    expect(service.pendingCount.value, 1);
  });

  test(
    'a reported removal that leaves the card entry is retried without resending',
    () async {
      manager.card = [notification(NotificationEvent.notificationLocalDelete)];
      manager.leaveOnCard = true;
      await process(remove: true);
      expect((await store.getAllNotifications()).single.deletePending, 1);
      expect(service.removedSeq.value, isNull);
      manager.leaveOnCard = false;
      await process(remove: true);
      expect(sends, 1);
      expect(service.currentNotifications.value, isEmpty);
      expect((await store.getAllNotifications()).single.deletePending, 0);
    },
  );

  test('a failed read does not poison later queued processing', () async {
    manager.card = [notification(NotificationEvent.notificationLocalEnable)];
    manager.beforeFirstRead = () async => throw StateError('Disconnected');
    await Future.wait([process(send: false), process()]);
    expect(sends, 1);
    expect(service.isProcessing.value, isFalse);
  });

  test(
    'a send request queued behind a badge-only fetch is not discarded',
    () async {
      manager.card = [notification(NotificationEvent.notificationLocalEnable)];
      final entered = Completer<void>(), release = Completer<void>();
      manager.beforeFirstRead = () async {
        entered.complete();
        await release.future;
      };
      final badge = process(send: false);
      await entered.future;
      final sending = process();
      release.complete();
      await Future.wait([badge, sending]);
      expect(sends, 1);
      expect(service.isProcessing.value, isFalse);
    },
  );

  test(
    'a borrowed channel is not queued behind a job waiting for its owner',
    () async {
      manager.card = [notification(NotificationEvent.notificationLocalEnable)];
      late Future<void> queued;
      await manager.adapter.runExclusive(() async {
        queued = process(send: false);
        await process(channel: _Channel(manager.adapter));
      });
      await queued;
      expect(sends, 1);
      expect(service.isProcessing.value, isFalse);
    },
  );

  test('a changed card cannot inherit a queued notification job', () async {
    manager.card = [notification(NotificationEvent.notificationLocalDelete)];
    manager.eidValue = '89049032000000000000000000000002';
    await process();
    expect(sends, 0);
    await expectLater(
      service.removeFromCard(
        manager,
        _Channel(manager.adapter),
        7,
        expectedEid: eid,
      ),
      throwsStateError,
    );
    expect(manager.removed, isEmpty);
  });

  test('a reused sequence with another payload is not suppressed', () async {
    manager.card = [notification(NotificationEvent.notificationLocalEnable)];
    await process();
    manager.card = [notification(NotificationEvent.notificationLocalDelete)];
    await process();
    expect(sends, 2);
  });

  test('migration preserves deduplication of existing sent history', () async {
    final n = notification(NotificationEvent.notificationLocalDelete);
    final record = NotificationRecord(
      eid: eid,
      iccid: '10',
      seqNumber: 7,
      content: base64Encode(n.encode()),
      timestamp: 1,
      status: 1,
    );
    await db.insert('notifications', record.toMap());
    await DatabaseService.createNotificationDeliveryReceipts(db);
    await store.deleteNotification(eid, 7, '10');
    expect(
      await store.isNotificationSent(eid, 7, '10', content: record.content),
      isTrue,
    );
    expect(
      await store.isNotificationSent(
        'other-card',
        7,
        '10',
        content: record.content,
      ),
      isFalse,
    );
    expect(
      await store.isNotificationSent(eid, 7, '20', content: record.content),
      isFalse,
    );
  });
}

class _Manager extends ProfileManager {
  _Manager(super.adapter);
  var card = <PendingNotification>[];
  final removed = <int>[];
  String eidValue = eid;
  bool leaveOnCard = false;
  var removalStatus = NotificationSentResponse_deleteNotificationStatus.ok;
  Future<void> Function()? beforeFirstRead;
  @override
  Future<String> getEid({Channel? useChannel}) async => eidValue;
  @override
  Future<Channel> openSession({List<String>? aids}) async => _Channel(adapter);
  @override
  Future<List<PendingNotification>> retrieveNotifications({
    Channel? useChannel,
  }) async {
    final read = beforeFirstRead;
    beforeFirstRead = null;
    await read?.call();
    return card.toList();
  }

  @override
  Future<PendingNotification> resolveNotification(
    PendingNotification n, {
    Channel? useChannel,
  }) async => n;
  @override
  Future<NotificationSentResponse_deleteNotificationStatus?> removeNotification(
    int seqNumber, {
    Channel? useChannel,
  }) async {
    if (removalStatus == NotificationSentResponse_deleteNotificationStatus.ok &&
        !leaveOnCard) {
      removed.add(seqNumber);
      card.removeWhere(
        (n) => ProfileManager.extractMetadata(n)?.seqNumber == seqNumber,
      );
    }
    return removalStatus;
  }
}

class _Adapter extends BaseAdapter {
  _Adapter() : super(Logger('NotificationTest')) {
    updateConnectedReader(Reader(id: 'ble:test', name: 'Test', source: this));
  }
  @override
  Stream<EuiccPortState> get stateStream => const Stream.empty();
  @override
  bool get requiresRefresh => false;
  @override
  String? get lastAtr => null;
  @override
  Future<List<Reader>> listReaders({bool force = false}) async => [];
  @override
  Future<void> connect(Reader r) async {
    updateConnectedReader(r);
  }

  @override
  Future<void> disconnect() async {}
  @override
  Future<Channel> openChannel({List<String>? aids}) async => _Channel(this);
  @override
  Future<Uint8List> sendRawApdu(Uint8List apdu) => throw UnimplementedError();
}

class _Channel implements Channel {
  _Channel(this.adapter);
  @override
  final Adapter adapter;
  @override
  String? get aid => null;
  @override
  int get channelNumber => 1;
  @override
  Future<void> close() async {}
  @override
  Future<Uint8List> transmit(
    int cla,
    int ins,
    int p1,
    int p2, [
    Uint8List? data,
    int? le,
  ]) => throw UnimplementedError();
}
