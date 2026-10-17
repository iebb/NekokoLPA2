import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:nlpa2/pages/download_profile_page.dart';
import 'package:nlpa2/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/adapter/euicc_adapter.dart';
import 'package:nlpa2/adapter/se_hal_adapter.dart';
import 'package:nlpa2/adapter/qrtr/qrtr_reader_adapter.dart';
import 'package:nlpa2/utils/error_codes.dart';
import 'package:nlpa2/adapter/composite_adapter.dart';
import 'package:nlpa2/adapter/ccid/ccid_adapter.dart';
import 'package:nlpa2/adapter/omapi/omapi_adapter.dart';
import 'package:nlpa2/adapter/se_hal_host.dart';
import 'package:nlpa2/logic/profile_manager.dart';
import 'package:nlpa2/utils/hex_utils.dart';
import 'package:nlpa2/utils/iccid_formatter.dart';
import 'package:nlpa2/utils/apdu_exception.dart';
import 'package:nlpa2/models/asn1/rsp_definitions.g.dart';
import 'package:nlpa2/models/euicc_profile.dart';
import 'package:nlpa2/services/database_service.dart';
import 'package:nlpa2/services/notification_service.dart';
import 'package:nlpa2/settings/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <String>[];
  final requests = <MethodCall>[];
  setUp(() async {
    final verifyDelay = ProfileManager.halVerifyDelay;
    ProfileManager.halVerifyDelay = (_) => Duration.zero;
    addTearDown(() => ProfileManager.halVerifyDelay = verifyDelay);
    await AppSettings().setHalUseBorrowed(1, false);
    await AppSettings().setHalUseBorrowed(2, false);
    calls.clear();
    requests.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('nlpa2/qrtr'), (
          call,
        ) async {
          calls.add(call.method);
          requests.add(call);
          if (call.method == 'hasPermission') return true;
          if ([
            'halInvalidateSessions',
            'halEndDownload',
            'halOpenOwned',
            'halCloseOwned',
            'halUseBorrowed',
          ].contains(call.method))
            return null;
          if (call.method == 'halDownload') {
            final data = (call.arguments as Map)['data'] as Uint8List;
            if (data[1] == 0x2E)
              return HexUtils.hexToBytes(
                'BF2E128010000000000000000000000000000000009000',
              );
            return HexUtils.hexToBytes('9000');
          }
          if (call.method == 'halSwitchProfile') {
            return HexUtils.hexToBytes(
              (call.arguments as Map)['enable'] == true
                  ? 'BF31038001009000'
                  : 'BF32038001009000',
            );
          }
          if (call.method == 'halAtr') return HexUtils.hexToBytes('3B00');
          if (call.method == 'halRead') {
            final a = (call.arguments as Map)['data'] as Uint8List;
            if (a[6] == 0x3E) {
              return HexUtils.hexToBytes(
                'BF3E125A10890490320000000000000000000000009000',
              );
            }
            if (a[6] == 0x2D) return HexUtils.hexToBytes('BF2D02A0009000');
          }
          throw StateError('Unexpected privileged call: ${call.method}');
        });
  });
  tearDown(() async {
    // Drain process-wide recovery state without any real privileged access.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('nlpa2/qrtr'), (
          call,
        ) async {
          if (call.method == 'halAtr') return HexUtils.hexToBytes('3B00');
          return null;
        });
    await SeHalHost.halAtr(1);
  });
  for (final qrtrEnabled in [false, true]) {
    for (final halEnabled in [false, true]) {
      test(
        'independent QRTR=$qrtrEnabled and SE HAL=$halEnabled gates',
        () async {
          final settings = AppSettings();
          final originalQrtr = settings.enableQrtrConnector;
          final originalHal = settings.enableSeHalConnector;
          final composite = CompositeAdapter();
          addTearDown(() async {
            await composite.disconnect();
            await settings.setEnableQrtrConnector(originalQrtr);
            await settings.setEnableSeHalConnector(originalHal);
          });
          await settings.setEnableQrtrConnector(qrtrEnabled);
          expect(settings.enableSeHalConnector, originalHal);
          await settings.setEnableSeHalConnector(halEnabled);
          expect(settings.enableQrtrConnector, qrtrEnabled);
          final qrtr = _TestQrtrAdapter();
          expect(qrtr.isEnabled, qrtrEnabled);
          if (!qrtrEnabled) expect(await qrtr.listReaders(), isEmpty);
          final hal = _OwnedReconnectAdapter();
          for (final entry in [
            (qrtrEnabled, Reader(id: 'qrtr:test', name: 'QRTR', source: qrtr)),
            (
              halEnabled,
              Reader(id: 'hal:SIM1:owned', name: 'SE HAL', source: hal),
            ),
          ]) {
            if (entry.$1) {
              await composite.connect(entry.$2);
              expect(composite.connectedReader?.id, entry.$2.id);
              expect(entry.$2.source.connectedReader?.id, entry.$2.id);
              await composite.disconnect();
            } else {
              await expectLater(
                composite.connect(entry.$2),
                throwsA(isA<AppException>()),
              );
              expect(composite.connectedReader, isNull);
              expect(entry.$2.source.connectedReader, isNull);
            }
          }
        },
      );
    }
  }
  for (final owned in [false, true]) {
    test('failed composite reconnect can retry (owned=$owned)', () async {
      final settings = AppSettings();
      final wasEnabled = settings.enableSeHalConnector;
      await settings.setEnableSeHalConnector(true);
      await settings.setHalUseBorrowed(1, !owned);
      final composite = CompositeAdapter();
      addTearDown(() async {
        await composite.disconnect();
        await settings.setEnableSeHalConnector(wasEnabled);
      });
      final hal = _OwnedReconnectAdapter();
      final reader = Reader(
        id: 'hal:SIM1${owned ? ":owned" : ""}',
        name: 'HAL',
        source: hal,
      );
      final openMethod = owned ? 'halOpenOwned' : 'halUseBorrowed';
      var unavailable = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('nlpa2/qrtr'), (
            call,
          ) async {
            calls.add(call.method);
            if (call.method == openMethod && unavailable) {
              throw PlatformException(code: 'NO_SERVICE');
            }
            if (call.method == 'halRead') {
              return HexUtils.hexToBytes(
                'BF3E125A10890490320000000000000000000000009000',
              );
            }
            return null;
          });
      await composite.connect(reader);
      unavailable = true;
      await expectLater(
        composite.reconnect(),
        throwsA(isA<PlatformException>()),
      );
      expect(hal.connectedReader, isNull);
      expect(composite.connectedReader, isNull);
      unavailable = false;
      calls.clear();
      // The same path used by the next explicit profile refresh.
      await composite.connect(reader);
      final channel = await composite.openChannel();
      expect(
        await ProfileManager(composite).getEid(useChannel: channel),
        '89049032000000000000000000000000',
      );
      expect(hal.connectedReader?.id, reader.id);
      expect(composite.connectedReader?.id, reader.id);
      expect(calls, [openMethod, 'halRead', 'halRead']);
      await channel.close();
    });
  }
  for (final failAt in ['halEndDownload', 'halCloseOwned']) {
    for (final owned in [false, true]) {
      for (final nextSlot in [1, 2]) {
        test(
          'unconfirmed $failAt recovers SIM$nextSlot without stale close (owned=$owned)',
          () async {
            final adapter = SeHalAdapter();
            adapter.updateConnectedReader(
              Reader(
                id: 'hal:SIM1${owned ? ":owned" : ""}',
                name: 'HAL',
                source: adapter,
              ),
            );
            var nativeRegistered = true;
            var nativeDownload = true;
            var restored = false;
            var invalidationFails = false;
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
                .setMockMethodCallHandler(const MethodChannel('nlpa2/qrtr'), (
                  call,
                ) async {
                  calls.add(call.method);
                  requests.add(call);
                  if (!restored && call.method == failAt)
                    throw PlatformException(code: 'NO_PERMISSION');
                  if (call.method == 'halEndDownload') {
                    nativeDownload = false;
                    return null;
                  }
                  if (call.method == 'halCloseOwned') {
                    if (restored) fail('A stale close must never be retried');
                    nativeRegistered = false;
                    return null;
                  }
                  if (call.method == 'halInvalidateSessions') {
                    if (invalidationFails)
                      throw PlatformException(code: 'NO_PERMISSION');
                    expect((call.arguments as Map)['slot'], 1);
                    nativeRegistered = false;
                    nativeDownload = false;
                    return null;
                  }
                  if (call.method == 'halAtr')
                    return HexUtils.hexToBytes('3B00');
                  if (call.method == 'halOpenOwned' ||
                      call.method == 'halUseBorrowed') {
                    expect(nativeRegistered, false);
                    expect(nativeDownload, false);
                    nativeRegistered = true;
                    return null;
                  }
                  fail('Unexpected call: ${call.method}');
                });
            await adapter.disconnect();
            expect(adapter.connectedReader, isNull);
            expect(nativeRegistered, true);
            restored = true;
            calls.clear();
            await adapter.disconnect();
            expect(calls, isEmpty);
            invalidationFails = true;
            await expectLater(
              SeHalHost.halAtr(nextSlot),
              throwsA(isA<PlatformException>()),
            );
            expect(calls, ['halInvalidateSessions']);
            invalidationFails = false;
            calls.clear();
            // The actual bridge calls used by SeHalAdapter.connect.
            await SeHalHost.halAtr(nextSlot);
            if (owned)
              await SeHalHost.halOpenOwned(nextSlot);
            else
              await SeHalHost.halUseBorrowed(nextSlot);
            expect(calls, [
              'halInvalidateSessions',
              'halAtr',
              owned ? 'halOpenOwned' : 'halUseBorrowed',
            ]);
            expect(nativeRegistered, true);
          },
        );
      }
    }
  }
  test('one HAL reader per slot defaults to owned mode', () async {
    final settings = AppSettings();
    await settings.setHalUseBorrowed(1, false);
    await settings.setHalUseBorrowed(2, false);
    final adapter = SeHalAdapter();
    final readers = [adapter.readerForSlot(1), adapter.readerForSlot(2)];
    expect(readers.map((r) => r.name), ['SE HAL-1', 'SE HAL-2']);
    expect(readers.map((r) => r.id), ['hal:SIM1:owned', 'hal:SIM2:owned']);
    await settings.setHalUseBorrowed(2, true);
    try {
      expect(adapter.readerForSlot(1).id, 'hal:SIM1:owned');
      expect(adapter.readerForSlot(2).id, 'hal:SIM2');
      expect(adapter.readerForSlot(2).name, 'SE HAL-2');
      expect(calls, isEmpty); // Changing mode never probes or mutates a card.
      await expectLater(
        settings.setHalUseBorrowed(3, true),
        throwsArgumentError,
      );
      expect(() => adapter.readerForSlot(0), throwsArgumentError);
    } finally {
      await settings.setHalUseBorrowed(2, false);
    }
  });
  for (final borrowed in [false, true]) {
    test(
      'ownership change rejects stale Reader before HAL access (borrowed=$borrowed)',
      () async {
        final settings = AppSettings();
        await settings.setHalUseBorrowed(1, !borrowed);
        final adapter = SeHalAdapter();
        final stale = adapter.readerForSlot(1);
        final unaffected = adapter.readerForSlot(2);
        await settings.setHalUseBorrowed(1, borrowed);
        calls.clear();
        await expectLater(adapter.connect(stale), throwsStateError);
        expect(calls, isEmpty);
        final transport = _OwnedReconnectAdapter();
        final fresh = transport.readerForSlot(1);
        await transport.connect(fresh);
        addTearDown(transport.disconnect);
        expect(transport.connectedReader?.id, fresh.id);
        expect(calls, contains(borrowed ? 'halUseBorrowed' : 'halOpenOwned'));
        expect(
          calls,
          isNot(contains(borrowed ? 'halOpenOwned' : 'halUseBorrowed')),
        );
        expect(adapter.readerForSlot(2).id, unaffected.id);
      },
    );
    test(
      'composite rejects stale mode even for an already connected Reader (borrowed=$borrowed)',
      () async {
        final settings = AppSettings();
        final enabled = settings.enableSeHalConnector;
        await settings.setEnableSeHalConnector(true);
        await settings.setHalUseBorrowed(1, !borrowed);
        final adapter = _OwnedReconnectAdapter();
        final composite = CompositeAdapter();
        addTearDown(() async {
          await composite.disconnect();
          await settings.setEnableSeHalConnector(enabled);
        });
        final stale = adapter.readerForSlot(1);
        await composite.connect(stale);
        await settings.setHalUseBorrowed(1, borrowed);
        calls.clear();
        await expectLater(composite.connect(stale), throwsStateError);
        expect(calls, isEmpty);
        await composite.disconnect();
        await composite.connect(adapter.readerForSlot(1));
        expect(calls, contains(borrowed ? 'halUseBorrowed' : 'halOpenOwned'));
      },
    );
  }
  test(
    'queued composite connection revalidates ownership after acquiring the lock',
    () async {
      final settings = AppSettings();
      final enabled = settings.enableSeHalConnector;
      await settings.setEnableSeHalConnector(true);
      await settings.setHalUseBorrowed(1, true);
      final composite = CompositeAdapter();
      final adapter = _OwnedReconnectAdapter();
      addTearDown(() async {
        await composite.disconnect();
        await settings.setEnableSeHalConnector(enabled);
      });
      final stale = adapter.readerForSlot(1);
      final entered = Completer<void>();
      final release = Completer<void>();
      final busy = composite.runExclusive(() async {
        entered.complete();
        await release.future;
      });
      await entered.future;
      final pending = composite.connect(stale);
      final rejected = expectLater(pending, throwsStateError);
      await settings.setHalUseBorrowed(1, false);
      calls.clear();
      release.complete();
      await busy;
      await rejected;
      expect(calls, isEmpty);
      expect(composite.connectedReader, isNull);
    },
  );
  test(
    'queued composite connection honors disabled connector after acquiring the lock',
    () async {
      final settings = AppSettings();
      final enabled = settings.enableSeHalConnector;
      await settings.setEnableSeHalConnector(true);
      await settings.setHalUseBorrowed(1, true);
      final composite = CompositeAdapter();
      final adapter = _OwnedReconnectAdapter();
      addTearDown(() async {
        await composite.disconnect();
        await settings.setEnableSeHalConnector(enabled);
      });
      final stale = adapter.readerForSlot(1);
      final entered = Completer<void>();
      final release = Completer<void>();
      final busy = composite.runExclusive(() async {
        entered.complete();
        await release.future;
      });
      await entered.future;
      final pending = composite.connect(stale);
      final rejected = expectLater(pending, throwsA(isA<AppException>()));
      await settings.setEnableSeHalConnector(false);
      calls.clear();
      release.complete();
      await busy;
      await rejected;
      expect(calls, isEmpty);
      expect(composite.connectedReader, isNull);
    },
  );
  test(
    'direct HAL connect rejects disabled connector without privileged access',
    () async {
      final settings = AppSettings();
      final enabled = settings.enableSeHalConnector;
      await settings.setEnableSeHalConnector(false);
      addTearDown(() => settings.setEnableSeHalConnector(enabled));
      final adapter = SeHalAdapter();
      calls.clear();
      await expectLater(
        adapter.connect(adapter.readerForSlot(1)),
        throwsStateError,
      );
      expect(calls, isEmpty);
    },
  );
  for (final slot in [1, 2]) {
    test('HAL reads and mutations retain SIM$slot routing', () async {
      final adapter = SeHalAdapter();
      final reader = Reader(
        id: 'hal:SIM$slot',
        name: 'SE HAL-$slot',
        source: adapter,
      );
      adapter.updateConnectedReader(reader);
      final channel = await adapter.openChannel() as HalDownloadChannel;
      await ProfileManager(
        adapter,
      ).enableProfile('8900000000000000000', useChannel: channel);
      await adapter.disconnect();
      final halCalls = requests.where((c) => c.method.startsWith('hal'));
      expect(
        halCalls.map((c) => (c.arguments as Map)['slot']),
        everyElement(slot),
      );
      expect(halCalls.any((c) => c.method == 'halSwitchProfile'), isTrue);
      expect(channel.slot, slot);
    });
  }
  test(
    'same reader reconnect permanently invalidates the old channel',
    () async {
      final adapter = _OwnedReconnectAdapter();
      final reader = Reader(id: 'hal:SIM1:owned', name: 'HAL', source: adapter);
      await adapter.connect(reader);
      final old = await adapter.openChannel() as HalDownloadChannel;
      await adapter.reconnect();
      final fresh = await adapter.openChannel();
      calls.clear();
      expect(
        () => old.transmit(
          0x80,
          0xE2,
          0x91,
          0,
          HexUtils.hexToBytes('BF3E035C015A'),
        ),
        throwsStateError,
      );
      expect(
        () => old.loadBpp(HexUtils.hexToBytes('BF3600'), [3]),
        throwsStateError,
      );
      expect(calls, isEmpty);
      await fresh.transmit(
        0x80,
        0xE2,
        0x91,
        0,
        HexUtils.hexToBytes('BF3E035C015A'),
      );
      expect(calls, ['halRead']);
    },
  );
  for (final download in [false, true]) {
    test(
      'channel checks its generation after waiting for the lock (download=$download)',
      () async {
        final adapter = SeHalAdapter();
        final reader = Reader(id: 'hal:SIM1', name: 'HAL', source: adapter);
        adapter.updateConnectedReader(reader);
        final channel = await adapter.openChannel() as HalDownloadChannel;
        final entered = Completer<void>();
        final changeConnection = Completer<void>();
        final reconnect = adapter.runExclusive(() async {
          entered.complete();
          await changeConnection.future;
          adapter.updateConnectedReader(null);
          adapter.updateConnectedReader(reader);
        });
        await entered.future;
        calls.clear();
        final queued = download
            ? channel.loadBpp(HexUtils.hexToBytes('BF3600'), [3])
            : channel.transmit(
                0x80,
                0xE2,
                0x91,
                0,
                HexUtils.hexToBytes('BF3E035C015A'),
              );
        final rejected = expectLater(queued, throwsStateError);
        changeConnection.complete();
        await reconnect;
        await rejected;
        expect(calls, isEmpty);
      },
    );
  }
  test(
    'borrowed switch recovery re-registers the session without repeating the write',
    () async {
      var registered = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('nlpa2/qrtr'), (
            call,
          ) async {
            calls.add(call.method);
            if (call.method == 'halUseBorrowed') {
              registered = true;
              return null;
            }
            if (call.method == 'halEndDownload' ||
                call.method == 'halCloseOwned') {
              registered = false;
              return null;
            }
            if (call.method == 'halRead') {
              if (!registered)
                throw PlatformException(
                  code: 'SERVICE_ERROR',
                  message: 'channel session lost',
                );
              final data = (call.arguments as Map)['data'] as Uint8List;
              return HexUtils.hexToBytes(
                data[6] == 0x3E
                    ? 'BF3E125A10890490320000000000000000000000009000'
                    : 'BF2D02A0009000',
              );
            }
            if (call.method == 'halSwitchProfile') {
              registered =
                  false; // The modem REFRESH notification invalidated it.
              return HexUtils.hexToBytes('BF31038001009000');
            }
            throw StateError('Unexpected call: ${call.method}');
          });
      final adapter = _OwnedReconnectAdapter();
      final reader = Reader(id: 'hal:SIM1', name: 'HAL', source: adapter);
      final manager = ProfileManager(adapter);
      await adapter.connect(reader);
      var channel = await adapter.openChannel();
      await manager.enableProfile('8900000000000000000', useChannel: channel);
      await channel.close();
      await adapter.reconnect();
      channel = await adapter.openChannel();
      expect(await manager.listProfiles(useChannel: channel), isEmpty);
      expect(calls.where((c) => c == 'halSwitchProfile').length, 1);
      expect(calls.where((c) => c == 'halUseBorrowed').length, 2);
      expect(calls, isNot(contains('halOpenOwned')));
    },
  );
  test(
    'explicit refresh recovers an invalidated borrowed reader without a write',
    () async {
      var registered = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('nlpa2/qrtr'), (
            call,
          ) async {
            calls.add(call.method);
            if (call.method == 'halUseBorrowed') {
              registered = true;
              return null;
            }
            if (call.method == 'halEndDownload' ||
                call.method == 'halCloseOwned') {
              registered = false;
              return null;
            }
            if (call.method == 'halRead') {
              if (!registered)
                throw PlatformException(
                  code: 'SERVICE_ERROR',
                  message: 'SE HAL channel session lost',
                );
              final data = (call.arguments as Map)['data'] as Uint8List;
              return HexUtils.hexToBytes(
                data[6] == 0x3E
                    ? 'BF3E125A10890490320000000000000000000000009000'
                    : 'BF2D02A0009000',
              );
            }
            throw StateError('Unexpected call: ${call.method}');
          });
      final adapter = _OwnedReconnectAdapter();
      final reader = Reader(id: 'hal:SIM1', name: 'HAL', source: adapter);
      final manager = ProfileManager(adapter);
      await adapter.connect(reader);
      final old = await adapter.openChannel();
      registered =
          false; // External SIM state notification invalidates borrowing.
      await expectLater(
        manager.listProfiles(useChannel: old),
        throwsA(isA<PlatformException>()),
      );
      calls.clear();
      for (var refresh = 0; refresh < 2; refresh++) {
        await adapter.reconnect();
        final channel = await adapter.openChannel(); // Verifies readable ISD-R.
        expect(await manager.listProfiles(useChannel: channel), isEmpty);
      }
      expect(calls.where((c) => c == 'halUseBorrowed').length, 2);
      expect(calls, isNot(contains('halOpenOwned')));
      expect(calls, isNot(contains('halSwitchProfile')));
      expect(calls, isNot(contains('halDownload')));
    },
  );
  test('stale HAL channel refuses a different connected slot', () async {
    final adapter = SeHalAdapter();
    adapter.updateConnectedReader(
      Reader(id: 'hal:SIM1', name: 'SIM1', source: adapter),
    );
    final channel = await adapter.openChannel();
    adapter.updateConnectedReader(
      Reader(id: 'hal:SIM2', name: 'SIM2', source: adapter),
    );
    requests.clear();
    expect(
      () => channel.transmit(
        0x80,
        0xE2,
        0x91,
        0,
        HexUtils.hexToBytes('BF3E035C015A'),
      ),
      throwsStateError,
    );
    expect(requests, isEmpty);
  });
  test('owned HAL route opens once and releases on disconnect', () async {
    final adapter = SeHalAdapter();
    final reader = Reader(id: 'hal:SIM1:owned', name: 'Owned', source: adapter);
    await SeHalHost.halOpenOwned(SeHalAdapter.slotFor(reader));
    adapter.updateConnectedReader(reader);
    final channel = await adapter.openChannel();
    await channel.close();
    expect(calls.where((c) => c == 'halOpenOwned').length, 1);
    expect(calls, isNot(contains('halCloseOwned')));
    await adapter.disconnect();
    expect(calls.last, 'halCloseOwned');
    expect(
      requests
          .where((c) => c.method.startsWith('hal'))
          .map((c) => (c.arguments as Map)['slot']),
      everyElement(1),
    );
  });
  test('stale HAL channel refuses another mode in the same slot', () async {
    final adapter = SeHalAdapter();
    adapter.updateConnectedReader(
      Reader(id: 'hal:SIM1', name: 'Legacy', source: adapter),
    );
    final channel = await adapter.openChannel();
    adapter.updateConnectedReader(
      Reader(id: 'hal:SIM1:owned', name: 'Owned', source: adapter),
    );
    requests.clear();
    expect(
      () => channel.transmit(
        0x80,
        0xE2,
        0x91,
        0,
        HexUtils.hexToBytes('BF3E035C015A'),
      ),
      throwsStateError,
    );
    expect(requests, isEmpty);
  });
  test('invalid HAL slot is rejected before contacting the card', () async {
    final adapter = SeHalAdapter();
    expect(
      () => SeHalAdapter.slotFor(
        Reader(id: 'hal:SIM3', name: 'SIM3', source: adapter),
      ),
      throwsArgumentError,
    );
    expect(requests.where((c) => c.method.startsWith('hal')), isEmpty);
  });
  test('notification removal requires exact successfully sent backup', () {
    NotificationRecord record({
      int status = 1,
      int sequence = 7,
      String content = 'signed',
      String server = 'smdp.example',
    }) => NotificationRecord(
      eid: 'eid',
      iccid: 'iccid',
      seqNumber: sequence,
      content: content,
      timestamp: 0,
      status: status,
      notificationServer: server,
    );
    validateHalNotificationBackup(record(), 7, 'signed', 'smdp.example');
    for (final bad in [
      null,
      record(status: 0),
      record(status: 2),
      record(sequence: 8),
      record(content: 'other'),
      record(server: 'other'),
    ]) {
      expect(
        () => validateHalNotificationBackup(bad, 7, 'signed', 'smdp.example'),
        throwsStateError,
      );
    }
  });
  test('delete uses dedicated native entry with padded identity', () async {
    final adapter = SeHalAdapter();
    adapter.updateConnectedReader(
      Reader(id: 'hal:SIM1', name: 'SE HAL', source: adapter),
    );
    final channel = await adapter.openChannel();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('nlpa2/qrtr'), (
          call,
        ) async {
          calls.add(call.method);
          requests.add(call);
          if (call.method == 'halRead')
            return HexUtils.hexToBytes(
              'BF3E125A10890490320000000000000000000000009000',
            );
          if (call.method == 'halDeleteProfile')
            return HexUtils.hexToBytes('BF33038001009000');
          throw StateError('Unexpected call');
        });
    await ProfileManager(
      adapter,
    ).deleteProfile('8900000000000000000', useChannel: channel);
    final args =
        requests.singleWhere((c) => c.method == 'halDeleteProfile').arguments
            as Map;
    expect(args['iccid'], HexUtils.hexToBytes('980000000000000000F0'));
    expect(calls, ['halRead', 'halRead', 'halDeleteProfile']);
  });
  test(
    'rename sends UTF8 through dedicated entry and verifies returned nickname',
    () async {
      final adapter = SeHalAdapter();
      adapter.updateConnectedReader(
        Reader(id: 'hal:SIM1', name: 'SE HAL', source: adapter),
      );
      final channel = await adapter.openChannel();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('nlpa2/qrtr'), (
            call,
          ) async {
            calls.add(call.method);
            requests.add(call);
            if (call.method == 'halRenameProfile')
              return HexUtils.hexToBytes('BF29038001009000');
            if (call.method == 'halRead') {
              final a = (call.arguments as Map)['data'] as Uint8List;
              if (a[6] == 0x3E)
                return HexUtils.hexToBytes(
                  'BF3E125A10890490320000000000000000000000009000',
                );
              return HexUtils.hexToBytes(
                'BF2D1CA01AE3185A0A980000000000000000F09F7001009006E697A5E69CAC9000',
              );
            }
            throw StateError('Unexpected call');
          });
      await ProfileManager(
        adapter,
      ).renameProfile('8900000000000000000', '日本', useChannel: channel);
      final args =
          requests.singleWhere((c) => c.method == 'halRenameProfile').arguments
              as Map;
      expect(args['nickname'], HexUtils.hexToBytes('E697A5E69CAC'));
      expect(calls.where((c) => c == 'halRenameProfile').length, 1);
    },
  );
  test('HAL nickname verification retains parsed tags', () async {
    final adapter = SeHalAdapter();
    adapter.updateConnectedReader(
      Reader(id: 'hal:SIM1', name: 'HAL', source: adapter),
    );
    final channel = await adapter.openChannel();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('nlpa2/qrtr'), (
          call,
        ) async {
          calls.add(call.method);
          if (call.method == 'halRenameProfile')
            return HexUtils.hexToBytes('BF29038001009000');
          if (call.method == 'halRead') {
            final data = (call.arguments as Map)['data'] as Uint8List;
            if (data[6] == 0x3E)
              return HexUtils.hexToBytes(
                'BF3E125A10890490320000000000000000000000009000',
              );
            return Uint8List.fromList([
              ...ProfileInfoListResponse(
                profileInfoListOk: [
                  ProfileInfo(
                    iccid: HexUtils.hexToBytes('980000000000000000F0'),
                    profileNickname: 'Name\nt:test',
                  ),
                ],
              ).encode(),
              0x90,
              0,
            ]);
          }
          throw StateError('Unexpected call');
        });
    await ProfileManager(
      adapter,
    ).renameProfile('8900000000000000000', 'Name\nt:test', useChannel: channel);
    expect(calls.where((c) => c == 'halRenameProfile'), hasLength(1));
  });
  test('HAL reads ignore configured request splitting MSS', () async {
    final settings = AppSettings();
    final mss = settings.mss;
    await settings.setMss(1);
    addTearDown(() => settings.setMss(mss));
    final adapter = SeHalAdapter();
    adapter.updateConnectedReader(
      Reader(id: 'hal:SIM1', name: 'HAL', source: adapter),
    );
    final channel = await adapter.openChannel();
    expect(
      await ProfileManager(adapter).listProfiles(useChannel: channel),
      isEmpty,
    );
    final reads = requests.where((c) => c.method == 'halRead');
    expect(reads, hasLength(2));
    for (final read in reads) {
      final data = (read.arguments as Map)['data'] as Uint8List;
      expect(data[0], 0x81);
      expect(data[2], 0x91);
    }
  });
  test('unknown delete outcome is never retried', () async {
    final adapter = SeHalAdapter();
    adapter.updateConnectedReader(
      Reader(id: 'hal:SIM1', name: 'SE HAL', source: adapter),
    );
    final channel = await adapter.openChannel();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('nlpa2/qrtr'), (
          call,
        ) async {
          calls.add(call.method);
          if (call.method == 'halRead')
            return HexUtils.hexToBytes(
              'BF3E125A10890490320000000000000000000000009000',
            );
          throw PlatformException(code: 'DEAD_OBJECT');
        });
    await expectLater(
      ProfileManager(
        adapter,
      ).deleteProfile('8900000000000000000', useChannel: channel),
      throwsA(isA<PlatformException>()),
    );
    expect(calls.where((c) => c == 'halDeleteProfile').length, 1);
  });
  for (final digits in ['8900000000000000000', '89000000000000000000']) {
    test(
      'installation ICCID matches profile list for ${digits.length} digits',
      () async {
        final adapter = SeHalAdapter();
        adapter.updateConnectedReader(
          Reader(id: 'hal:SIM1', name: 'SE HAL', source: adapter),
        );
        final channel = await adapter.openChannel();
        final bytes = HexUtils.hexToBytes(
          HexUtils.swapNibbles(digits.length.isOdd ? '${digits}F' : digits),
        );
        final rawMetadataIccid = HexUtils.swapNibbles(
          HexUtils.bytesToHex(bytes),
        );
        if (digits.length.isOdd) expect(rawMetadataIccid.endsWith('f'), isTrue);
        final expectedIccid = IccidFormatter.forDisplay(rawMetadataIccid);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(const MethodChannel('nlpa2/qrtr'), (
              call,
            ) async {
              if (call.method == 'halRead')
                return Uint8List.fromList([
                  ...ProfileInfoListResponse(
                    profileInfoListOk: [ProfileInfo(iccid: bytes)],
                  ).encode(),
                  0x90,
                  0,
                ]);
              throw StateError('Unexpected call');
            });
        final installed = await ProfileManager(
          adapter,
        ).listProfiles(useChannel: channel);
        expect(installed.single.iccid, digits);
        await expectLater(
          ProfileManager(
            adapter,
          ).listProfiles(useChannel: channel, requireKnownState: true),
          throwsStateError,
        );
        expect(
          installed.any(
            (p) => IccidFormatter.forDisplay(p.iccid) == expectedIccid,
          ),
          isTrue,
        );
        expect(IccidFormatter.forDisplay('${digits}F'), expectedIccid);
        expect(IccidFormatter.forDisplay('${digits}f'), expectedIccid);
        expect(
          IccidFormatter.forDisplay('8900000000000000001'),
          isNot(expectedIccid),
        );
      },
    );
  }
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('nlpa2/qrtr'), null);
  });
  test(
    'reads profiles without selecting or closing the borrowed channel',
    () async {
      final adapter = SeHalAdapter();
      adapter.updateConnectedReader(
        Reader(id: 'hal:SIM1', name: 'SE HAL', source: adapter),
      );
      final channel = await adapter.openChannel(aids: [SeHalAdapter.isdr]);
      expect(channel.channelNumber, 1);
      expect(
        await ProfileManager(adapter).listProfiles(useChannel: channel),
        isEmpty,
      );
      await channel.close();
      await adapter.cleanupChannels();
      await adapter.disconnect();
      expect(calls, ['halRead', 'halRead', 'halEndDownload', 'halCloseOwned']);
    },
  );
  test('rejects attempts to select a different applet', () async {
    final adapter = SeHalAdapter();
    adapter.updateConnectedReader(
      Reader(id: 'hal:SIM1', name: 'SE HAL', source: adapter),
    );
    await expectLater(
      adapter.openChannel(aids: ['A00000015141434C00']),
      throwsStateError,
    );
    expect(calls, isEmpty);
  });
  test(
    'routes challenge through the dedicated native download boundary',
    () async {
      final adapter = SeHalAdapter();
      adapter.updateConnectedReader(
        Reader(id: 'hal:SIM1', name: 'SE HAL', source: adapter),
      );
      final channel = await adapter.openChannel();
      final challenge = await ProfileManager(
        adapter,
      ).getEuiccChallenge(useChannel: channel);
      expect(challenge.length, 16);
      expect(calls, ['halRead', 'halRead', 'halDownload']);
    },
  );
  test(
    'sends a complete BPP with existing segment lengths in one call',
    () async {
      final adapter = SeHalAdapter();
      adapter.updateConnectedReader(
        Reader(id: 'hal:SIM1', name: 'SE HAL', source: adapter),
      );
      final channel = await adapter.openChannel();
      await ProfileManager(adapter).loadBoundProfilePackage(
        HexUtils.hexToBytes('BF3603BF2300'),
        useChannel: channel,
      );
      expect(calls, ['halRead', 'halDownload']);
      await channel.close();
      expect(calls, ['halRead', 'halDownload']);
    },
  );
  test('preserves every SGP.22 BPP segment across the HAL boundary', () async {
    final adapter = SeHalAdapter();
    adapter.updateConnectedReader(
      Reader(id: 'hal:SIM1', name: 'SE HAL', source: adapter),
    );
    final channel = await adapter.openChannel();
    final bpp = HexUtils.hexToBytes(
      'BF361CBF2300A006870101870102A1058803010203A203870104A303860105',
    );
    await ProfileManager(
      adapter,
    ).loadBoundProfilePackage(bpp, useChannel: channel);
    final args =
        requests.singleWhere((c) => c.method == 'halDownload').arguments as Map;
    expect(args['data'], bpp);
    expect(args['segments'], [6, 5, 3, 2, 5, 5, 2, 3]);
    expect(calls, ['halRead', 'halDownload']);
  });
  test(
    'activation uses the dedicated native entry, not raw APDUs or download approval',
    () async {
      final adapter = SeHalAdapter();
      adapter.updateConnectedReader(
        Reader(id: 'hal:SIM1', name: 'SE HAL', source: adapter),
      );
      final channel = await adapter.openChannel();
      expect(
        await ProfileManager(
          adapter,
        ).enableProfile('8900000000000000000', useChannel: channel),
        isTrue,
      );
      final args =
          requests.singleWhere((c) => c.method == 'halSwitchProfile').arguments
              as Map;
      expect(args['iccid'], HexUtils.hexToBytes('980000000000000000F0'));
      expect(
        args['eid'],
        HexUtils.hexToBytes('89049032000000000000000000000000'),
      );
      expect(calls, ['halRead', 'halRead', 'halSwitchProfile']);
    },
  );
  test(
    'rejects invalid activation targets without invoking native activation',
    () async {
      final adapter = SeHalAdapter();
      adapter.updateConnectedReader(
        Reader(id: 'hal:SIM1', name: 'SE HAL', source: adapter),
      );
      final channel = await adapter.openChannel();
      for (final iccid in [
        '89',
        '890000000000000000F',
        '0000000000000000000',
      ]) {
        await expectLater(
          ProfileManager(adapter).enableProfile(iccid, useChannel: channel),
          throwsArgumentError,
        );
      }
      expect(calls, ['halRead']);
    },
  );
  test(
    'disable uses native switch enable=false without raw commands',
    () async {
      final adapter = SeHalAdapter();
      adapter.updateConnectedReader(
        Reader(id: 'hal:SIM1', name: 'SE HAL', source: adapter),
      );
      final channel = await adapter.openChannel();
      expect(
        await ProfileManager(
          adapter,
        ).disableProfile('8900000000000000000', useChannel: channel),
        isTrue,
      );
      final args =
          requests.singleWhere((c) => c.method == 'halSwitchProfile').arguments
              as Map;
      expect(args['enable'], isFalse);
      expect(calls, ['halRead', 'halRead', 'halSwitchProfile']);
    },
  );
  for (final message in [
    'SIM changed during APDU; reply uncertain, do not retry',
    'SE HAL switch reply uncertain; do not retry',
    'android.os.DeadObjectException',
  ]) {
    for (final owned in [false, true]) {
      for (final enable in [false, true]) {
        test(
          'uncertain HAL switch verifies new session (owned=$owned enable=$enable reply=$message)',
          () async {
            var registered = false;
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
                .setMockMethodCallHandler(const MethodChannel('nlpa2/qrtr'), (
                  call,
                ) async {
                  calls.add(call.method);
                  if (call.method == 'halOpenOwned' ||
                      call.method == 'halUseBorrowed') {
                    registered = true;
                    return null;
                  }
                  if (call.method == 'halSwitchProfile') {
                    registered =
                        false; // SIM REFRESH invalidated the native session.
                    throw PlatformException(
                      code: message == 'android.os.DeadObjectException'
                          ? 'HAL_SWITCH_UNCERTAIN'
                          : 'SERVICE_ERROR',
                      message: message,
                    );
                  }
                  if (call.method == 'halRead') {
                    if (!registered) throw StateError('Stale session read');
                    return HexUtils.hexToBytes(
                      'BF3E125A10890490320000000000000000000000009000',
                    );
                  }
                  return null;
                });
            final adapter = _OwnedReconnectAdapter();
            await adapter.connect(
              Reader(
                id: 'hal:SIM1${owned ? ":owned" : ""}',
                name: 'HAL',
                source: adapter,
              ),
            );
            addTearDown(adapter.disconnect);
            final manager = _HalVerificationManager(adapter, enable);
            final profiles = await manager.switchHalProfileAndVerify(
              '8900000000000000000',
              enable,
            );
            expect(profiles.single.enabled, enable);
            expect(
              adapter.connectedReader?.eid,
              '89049032000000000000000000000000',
            );
            expect(manager.profileReads, 1);
            expect(calls.where((c) => c == 'halSwitchProfile'), hasLength(1));
            expect(
              calls.where(
                (c) => c == (owned ? 'halOpenOwned' : 'halUseBorrowed'),
              ),
              hasLength(2),
            );
            expect(
              calls.indexOf('halEndDownload'),
              greaterThan(calls.indexOf('halSwitchProfile')),
            );
          },
        );
      }
    }
  }
  for (final owned in [false, true]) {
    for (final failurePoint in ['read', 'open']) {
      for (final failures in [1, ProfileManager.halVerifyAttempts]) {
        test(
          'HAL read-back recovers without resending (owned=$owned point=$failurePoint failures=$failures)',
          () async {
            var switched = false;
            var remaining = failures;
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
                .setMockMethodCallHandler(const MethodChannel('nlpa2/qrtr'), (
                  call,
                ) async {
                  calls.add(call.method);
                  if (call.method == 'halSwitchProfile') {
                    switched = true;
                    return HexUtils.hexToBytes('BF31038001009000');
                  }
                  final opening =
                      call.method == 'halOpenOwned' ||
                      call.method == 'halUseBorrowed';
                  if (switched &&
                      remaining > 0 &&
                      (failurePoint == 'open'
                          ? opening
                          : call.method == 'halRead')) {
                    remaining--;
                    throw PlatformException(
                      code: 'SERVICE_ERROR',
                      message: failurePoint == 'open'
                          ? 'SIM changed while opening channel; reconnect reader'
                          : 'SIM changed during APDU; reply uncertain, do not retry',
                    );
                  }
                  if (call.method == 'halRead') {
                    return HexUtils.hexToBytes(
                      'BF3E125A10890490320000000000000000000000009000',
                    );
                  }
                  return null;
                });
            final adapter = _OwnedReconnectAdapter();
            await adapter.connect(
              Reader(
                id: 'hal:SIM1${owned ? ":owned" : ""}',
                name: 'HAL',
                source: adapter,
              ),
            );
            addTearDown(adapter.disconnect);
            final manager = _HalVerificationManager(adapter, true);
            final result = manager.switchHalProfileAndVerify(
              '8900000000000000000',
              true,
            );
            final exhausted = failures == ProfileManager.halVerifyAttempts;
            if (exhausted) {
              await expectLater(result, throwsA(isA<PlatformException>()));
              expect(manager.profileReads, 0);
            } else {
              expect((await result).single.enabled, isTrue);
              expect(manager.profileReads, 1);
            }
            expect(remaining, 0);
            expect(calls.where((c) => c == 'halSwitchProfile'), hasLength(1));
            expect(
              calls.where(
                (c) => c == (owned ? 'halOpenOwned' : 'halUseBorrowed'),
              ),
              hasLength(failures + (exhausted ? 1 : 2)),
            );
          },
        );
      }
    }
  }
  for (final status in ['9000', '9100']) {
    test(
      'HAL switch verifies confirmed/proactive response $status once',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(const MethodChannel('nlpa2/qrtr'), (
              call,
            ) async {
              calls.add(call.method);
              if (call.method == 'halSwitchProfile')
                return HexUtils.hexToBytes('BF3103800100$status');
              if (call.method == 'halRead')
                return HexUtils.hexToBytes(
                  'BF3E125A10890490320000000000000000000000009000',
                );
              return null;
            });
        final adapter = _OwnedReconnectAdapter();
        await adapter.connect(
          Reader(id: 'hal:SIM1:owned', name: 'HAL', source: adapter),
        );
        addTearDown(adapter.disconnect);
        final manager = _HalVerificationManager(adapter, true);
        expect(
          (await manager.switchHalProfileAndVerify(
            '8900000000000000000',
            true,
          )).single.enabled,
          isTrue,
        );
        expect(calls.where((c) => c == 'halSwitchProfile'), hasLength(1));
        expect(manager.profileReads, 1);
      },
    );
  }
  for (final failure in ['state mismatch', 'read failure', 'card changed']) {
    test('uncertain HAL switch remains unconfirmed on $failure', () async {
      var switched = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('nlpa2/qrtr'), (
            call,
          ) async {
            calls.add(call.method);
            if (call.method == 'halSwitchProfile') {
              switched = true;
              throw PlatformException(
                code: 'SERVICE_ERROR',
                message:
                    'SIM changed during APDU; reply uncertain, do not retry',
              );
            }
            if (call.method == 'halRead') {
              if (switched && failure == 'read failure')
                throw PlatformException(code: 'NO_SERVICE');
              return HexUtils.hexToBytes(
                switched && failure == 'card changed'
                    ? 'BF3E125A10890490320000000000000000000000019000'
                    : 'BF3E125A10890490320000000000000000000000009000',
              );
            }
            return null;
          });
      final adapter = _OwnedReconnectAdapter();
      await adapter.connect(
        Reader(id: 'hal:SIM1:owned', name: 'HAL', source: adapter),
      );
      addTearDown(adapter.disconnect);
      final manager = _HalVerificationManager(adapter, false);
      await expectLater(
        manager.switchHalProfileAndVerify('8900000000000000000', true),
        throwsA(
          failure == 'read failure'
              ? isA<PlatformException>()
              : isA<StateError>(),
        ),
      );
      expect(calls.where((c) => c == 'halSwitchProfile'), hasLength(1));
      expect(
        manager.profileReads,
        failure == 'state mismatch' ? ProfileManager.halVerifyAttempts : 0,
      );
      expect(
        calls.where((c) => c == 'halOpenOwned'),
        hasLength(
          failure == 'card changed' ? 2 : ProfileManager.halVerifyAttempts + 1,
        ),
      );
    });
  }
  for (final failure in ['reset in progress', 'permission revoked']) {
    test('HAL read-back after $failure', () async {
      var switched = false;
      var opens = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('nlpa2/qrtr'), (
            call,
          ) async {
            calls.add(call.method);
            if (call.method == 'halSwitchProfile') {
              switched = true;
              return HexUtils.hexToBytes('BF31038001009000');
            }
            if (call.method == 'halOpenOwned' && switched && opens++ == 0) {
              throw PlatformException(
                code: failure == 'reset in progress'
                    ? 'SERVICE_ERROR'
                    : 'NO_PERMISSION',
                message: 'SE HAL rejected channel open',
              );
            }
            if (call.method == 'halRead')
              return HexUtils.hexToBytes(
                'BF3E125A10890490320000000000000000000000009000',
              );
            return null;
          });
      final adapter = _OwnedReconnectAdapter();
      await adapter.connect(
        Reader(id: 'hal:SIM1:owned', name: 'HAL', source: adapter),
      );
      addTearDown(adapter.disconnect);
      final manager = _HalVerificationManager(adapter, true);
      final result = manager.switchHalProfileAndVerify(
        '8900000000000000000',
        true,
      );
      if (failure == 'reset in progress') {
        expect((await result).single.enabled, isTrue);
        expect(manager.profileReads, 1);
        expect(calls.where((c) => c == 'halOpenOwned'), hasLength(3));
      } else {
        await expectLater(result, throwsA(isA<PlatformException>()));
        expect(manager.profileReads, 0);
        expect(calls.where((c) => c == 'halOpenOwned'), hasLength(2));
      }
      expect(calls.where((c) => c == 'halSwitchProfile'), hasLength(1));
    });
  }
  for (final failure in [
    'permission',
    'unrelated service error',
    'card rejection',
  ]) {
    test('HAL switch does not suppress $failure', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('nlpa2/qrtr'), (
            call,
          ) async {
            calls.add(call.method);
            if (call.method == 'halSwitchProfile') {
              if (failure == 'card rejection')
                return HexUtils.hexToBytes('BF31038001029000');
              throw PlatformException(
                code: failure == 'permission'
                    ? 'NO_PERMISSION'
                    : 'SERVICE_ERROR',
                message: 'Access unavailable',
              );
            }
            if (call.method == 'halRead')
              return HexUtils.hexToBytes(
                'BF3E125A10890490320000000000000000000000009000',
              );
            return null;
          });
      final adapter = _OwnedReconnectAdapter();
      await adapter.connect(
        Reader(id: 'hal:SIM1:owned', name: 'HAL', source: adapter),
      );
      addTearDown(adapter.disconnect);
      final manager = _HalVerificationManager(adapter, true);
      await expectLater(
        manager.switchHalProfileAndVerify('8900000000000000000', true),
        throwsA(
          failure == 'card rejection'
              ? isA<StateError>()
              : isA<PlatformException>(),
        ),
      );
      expect(calls.where((c) => c == 'halSwitchProfile'), hasLength(1));
      expect(calls.where((c) => c == 'halOpenOwned'), hasLength(1));
      expect(manager.profileReads, 0);
    });
  }
  test(
    'uncertain native switch failure is never automatically retried',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('nlpa2/qrtr'), (
            call,
          ) async {
            calls.add(call.method);
            if (call.method == 'halRead')
              return HexUtils.hexToBytes(
                'BF3E125A10890490320000000000000000000000009000',
              );
            throw PlatformException(
              code: 'CHANNEL_LOST',
              message: 'Unknown switch result',
            );
          });
      final adapter = SeHalAdapter();
      adapter.updateConnectedReader(
        Reader(id: 'hal:SIM1', name: 'SE HAL', source: adapter),
      );
      final channel = await adapter.openChannel();
      await expectLater(
        ProfileManager(
          adapter,
        ).enableProfile('8900000000000000000', useChannel: channel),
        throwsA(isA<PlatformException>()),
      );
      expect(calls, ['halRead', 'halRead', 'halSwitchProfile']);
    },
  );
  test('HAL 91xx switch is never resubmitted by the manager', () async {
    final adapter = SeHalAdapter();
    adapter.updateConnectedReader(
      Reader(id: 'hal:SIM1:owned', name: 'Owned', source: adapter),
    );
    final channel = await adapter.openChannel();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('nlpa2/qrtr'), (
          call,
        ) async {
          calls.add(call.method);
          if (call.method == 'halRead')
            return HexUtils.hexToBytes(
              'BF3E125A10890490320000000000000000000000009000',
            );
          if (call.method == 'halSwitchProfile')
            return HexUtils.hexToBytes('BF31038001009100');
          throw StateError('Unexpected call');
        });
    calls.clear();
    await expectLater(
      ProfileManager(
        adapter,
      ).enableProfile('8900000000000000000', useChannel: channel),
      throwsA(isA<ProactiveRefreshException>()),
    );
    expect(calls, ['halRead', 'halSwitchProfile']);
  });
  test(
    'owned reconnect releases and reopens before the next state read',
    () async {
      final adapter = _OwnedReconnectAdapter();
      final reader = Reader(
        id: 'hal:SIM1:owned',
        name: 'Owned',
        source: adapter,
      );
      adapter.updateConnectedReader(reader);
      await adapter.reconnect();
      await adapter.openChannel();
      expect(calls, [
        'halEndDownload',
        'halCloseOwned',
        'halOpenOwned',
        'halRead',
      ]);
      expect(calls, isNot(contains('halSwitchProfile')));
    },
  );
  test(
    'HAL switching also works when ProfileManager owns the session',
    () async {
      final adapter = SeHalAdapter();
      adapter.updateConnectedReader(
        Reader(id: 'hal:SIM1', name: 'SE HAL', source: adapter),
      );
      expect(
        await ProfileManager(adapter).disableProfile('8900000000000000000'),
        isTrue,
      );
      expect(calls, ['halRead', 'halRead', 'halSwitchProfile']);
    },
  );
  for (final failAt in ['halEndDownload', 'halCloseOwned']) {
    for (final owned in [false, true]) {
      for (final usb in [false, true]) {
        test(
          'failed $failAt permits ${usb ? "USB" : "OMAPI"} switching (owned=$owned)',
          () async {
            final settings = AppSettings();
            final wasEnabled = settings.enableSeHalConnector;
            await settings.setEnableSeHalConnector(true);
            await settings.setHalUseBorrowed(1, !owned);
            final composite = CompositeAdapter();
            addTearDown(() async {
              await composite.disconnect();
              await settings.setEnableSeHalConnector(wasEnabled);
            });
            final hal = _OwnedReconnectAdapter();
            final reader = Reader(
              id: 'hal:SIM1${owned ? ":owned" : ""}',
              name: 'HAL',
              source: hal,
            );
            await composite.connect(reader);
            final staleChannel = await hal.openChannel();
            calls.clear();
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
                .setMockMethodCallHandler(const MethodChannel('nlpa2/qrtr'), (
                  call,
                ) async {
                  calls.add(call.method);
                  if (call.method == failAt) {
                    throw PlatformException(
                      code: owned ? 'NO_SERVICE' : 'PERMISSION_DENIED',
                    );
                  }
                  return null;
                });
            final BaseAdapter nextAdapter = usb
                ? _TestCcidAdapter()
                : _TestOmapiAdapter();
            final next = Reader(
              id: usb ? 'usb:test' : 'omapi:test',
              name: 'Next',
              source: nextAdapter,
            );
            await composite.connect(next);
            expect(hal.connectedReader, isNull);
            expect(hal.lastAtr, isNull);
            expect(composite.connectedReader, next);
            expect(nextAdapter.connectedReader, next);
            expect(
              calls,
              failAt == 'halEndDownload'
                  ? ['halEndDownload']
                  : ['halEndDownload', 'halCloseOwned'],
            );
            await expectLater(hal.openChannel(), throwsStateError);
            expect(
              () => staleChannel.transmit(0x80, 0xE2, 0x91, 0),
              throwsStateError,
            );
            final teardownCalls = List<String>.of(calls);
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
                .setMockMethodCallHandler(const MethodChannel('nlpa2/qrtr'), (
                  call,
                ) async {
                  calls.add(call.method);
                  return null; // Privileged access has returned.
                });
            await hal.disconnect();
            await composite.disconnect();
            expect(
              calls,
              teardownCalls,
            ); // No retry after privileged access returns.
          },
        );
      }
    }
  }
  for (final locale in [const Locale('en'), const Locale('ja')]) {
    testWidgets(
      'deep-link autoStart requires localized consent (${locale.languageCode})',
      (tester) async {
        final notifications = NotificationService();
        notifications.pendingCount.value = 3;
        addTearDown(() {
          notifications.pendingCount.value = 0;
          notifications.isProcessing.value = false;
          notifications.isFetching.value = false;
        });
        final l10n = await AppLocalizations.delegate.load(locale);
        final adapter = SeHalAdapter();
        final reader = Reader(id: 'hal:SIM1', name: 'SE HAL', source: adapter);
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: DownloadProfilePage(
              profileManager: ProfileManager(adapter),
              adapter: adapter,
              reader: reader,
              initialCode: r'LPA:1$rsp.example$UNUSED-TEST-CODE',
              autoStart: true,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(OutlinedButton), findsNothing);
        expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isTrue);
        for (final busy in [
          notifications.isProcessing,
          notifications.isFetching,
        ]) {
          busy.value = true;
          await tester.pump();
          expect(
            tester.widget<PopScope>(find.byType(PopScope)).canPop,
            isFalse,
          );
          busy.value = false;
          await tester.pump();
          expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isTrue);
        }
        expect(find.text(l10n.seHalDownloadTitle), findsNothing);
        expect(calls, isEmpty);
        await tester.ensureVisible(find.text(l10n.seHalDownloadUnusedQr));
        await tester.tap(find.text(l10n.seHalDownloadUnusedQr));
        await tester.pumpAndSettle();
        expect(find.text(l10n.seHalDownloadTitle), findsOneWidget);
        expect(calls, isEmpty);
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text(l10n.cancel),
          ),
        );
        await tester.pumpAndSettle();
        expect(calls, isEmpty);
        expect(notifications.pendingCount.value, 3);
        expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isTrue);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        expect(calls, ['halEndDownload']);
      },
    );
  }
}

// Avoid the host OS's Android permission gate; reconnect/disconnect and reads
// use the real adapter implementations and the existing MethodChannel mock.
class _OwnedReconnectAdapter extends SeHalAdapter {
  @override
  Future<void> connect(Reader reader) async {
    if (SeHalAdapter.ownsChannel(reader)) {
      await SeHalHost.halOpenOwned(SeHalAdapter.slotFor(reader));
    } else {
      await SeHalHost.halUseBorrowed(SeHalAdapter.slotFor(reader));
    }
    updateConnectedReader(reader);
  }
}

// Exercise real CompositeAdapter switching without touching reader hardware.
class _TestCcidAdapter extends CcidAdapter {
  @override
  Future<void> connect(Reader reader) async => updateConnectedReader(reader);
  @override
  Future<void> disconnect() async => updateConnectedReader(null);
}

class _TestOmapiAdapter extends OmapiAdapter {
  @override
  Future<void> connect(Reader reader) async => updateConnectedReader(reader);
  @override
  Future<void> disconnect() async => updateConnectedReader(null);
}

// Only the transport itself is mocked; exercise the real composite gates.
class _TestQrtrAdapter extends QrtrReaderAdapter {
  @override
  Future<void> connect(Reader reader) async => updateConnectedReader(reader);
  @override
  Future<void> disconnect() async => updateConnectedReader(null);
}

class _HalVerificationManager extends ProfileManager {
  _HalVerificationManager(super.adapter, this.enabled);
  final bool enabled;
  int profileReads = 0;
  @override
  Future<List<EuiccProfile>> listProfiles({
    Channel? useChannel,
    bool requireKnownState = false,
  }) async {
    expect(requireKnownState, isTrue);
    profileReads++;
    return [EuiccProfile(iccid: '8900000000000000000', enabled: enabled)];
  }
}
