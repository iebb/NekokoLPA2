import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:ble/ble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/adapter/euicc_adapter.dart';
import 'package:nlpa2/l10n/app_localizations.dart';
import 'package:nlpa2/main.dart' show navigatorKey;
import 'package:nlpa2/utils/error_codes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nlpa2/adapter/ble/linklan_adapter.dart';

Uint8List hex(String value) => LinklanProtocol.hexToBytes(value);

void main() {
  group('Linklan protocol and adapter', () {
    test('PSK is HMAC_SHA256(password, "SecurePbChannel")', () {
      // Synthetic password: any real card password must never live in a test.
      expect(
        LinklanProtocol.bytesToHex(
          LinklanProtocol.pskFromPassword('demo-card-pw'),
        ).toLowerCase(),
        'b4de772e4a9ccfeb4bf7c95f9066a8e54f6807c465cb0d0f200cb520330956d8',
      );
    });

    test('handshake derives the proof and the session key', () {
      // Synthetic randoms; the expected values are what the HMAC chain in
      // lpad/r4.a() produces, so a swapped key/message order fails here.
      final mac = LinklanProtocol.sessionMac(
        LinklanProtocol.pskFromPassword('demo-card-pw'),
        hex('00112233445566778899aabbccddeeff'),
        hex('ffeeddccbbaa99887766554433221100'),
      );
      expect(
        LinklanProtocol.bytesToHex(
          LinklanProtocol.authProof(
            mac,
            hex('ffeeddccbbaa99887766554433221100'),
          ),
        ).toLowerCase(),
        'd24712d0a61bbe4178c41abac97f20a689083f35ed10cfdf3515e3632cfe2860',
      );
      // mac[16:32] is the AES-CCM session key.
      expect(
        LinklanProtocol.bytesToHex(mac.sublist(16, 32)).toLowerCase(),
        '6f6fdc26befab108c7ec231c0ff9633c',
      );
    });

    test('AES-CCM matches the cross-implementation vector', () {
      final ct = LinklanProtocol.aesCcmEncrypt(
        hex('00112233445566778899aabbccddeeff'),
        hex('00112233445566778899aabb'),
        hex('000102030405060708090a0b0c0d0e0f'),
        hex('080012020801'),
      );
      expect(
        LinklanProtocol.bytesToHex(ct).toLowerCase(),
        '1adee9428e90f8af5925',
      );
      final pt = LinklanProtocol.aesCcmDecrypt(
        hex('00112233445566778899aabbccddeeff'),
        hex('00112233445566778899aabb'),
        hex('000102030405060708090a0b0c0d0e0f'),
        ct,
      );
      expect(LinklanProtocol.bytesToHex(pt).toLowerCase(), '080012020801');
    });

    test('protobuf framing matches the wire', () {
      // getDeviceInfo is {1: 0, 2: {1: 1}} -> 08 00 12 02 08 01
      expect(
        LinklanProtocol.bytesToHex(LinklanProtocol.getDeviceInfo()),
        '080012020801',
      );
      final prefixed = LinklanProtocol.withLengthPrefix(
        LinklanProtocol.getDeviceInfo(),
      );
      expect(LinklanProtocol.bytesToHex(prefixed), '0006080012020801');
      // The auth frame the card accepted: {1: 3, 2: {1: id, 3: {2: {1: cli, 2: proof}}}}
      final auth = LinklanProtocol.pbBytes(
        2,
        LinklanProtocol.concatAll([
          LinklanProtocol.pbBytes(1, hex('00112233445566778899aabbccddeeff')),
          LinklanProtocol.pbBytes(2, Uint8List(32)),
        ]),
      );
      final frame = LinklanProtocol.frame(
        LinklanProtocol.cmdSecurity,
        LinklanProtocol.concatAll([
          LinklanProtocol.pbInt(1, 0, always: true),
          LinklanProtocol.pbBytes(3, auth),
        ]),
      );
      expect(LinklanProtocol.bytesToHex(frame), startsWith('0803123A08001A36'));
    });

    test('transmitApdu uses zigzag fields and hex data', () {
      // transmitApdu also returns the SmartCardReq payload, not a full frame.
      final request = LinklanProtocol.pbDecode(
        LinklanProtocol.transmitApdu(
          channel: 4,
          cla: 0x80,
          ins: 0xE2,
          p1: 0x91,
          p2: 0x00,
          data: hex('BF3E00'),
        ),
      );
      expect(request[1], LinklanProtocol.scardTransmit);
      final tai = LinklanProtocol.pbDecode(
        LinklanProtocol.pbBytesOf(request, 4)!,
      );
      expect(tai[1], LinklanProtocol.zigzag(4));
      expect(tai[2], LinklanProtocol.zigzag(0x80));
      expect(tai[6], LinklanProtocol.zigzag(3));
      expect(utf8.decode(LinklanProtocol.pbBytesOf(tai, 7)!), 'BF3E00');
    });

    test('openChannel sends the AID as ASCII hex characters', () {
      // openChannel returns the SmartCardReq payload (the frame wrapper is added
      // by the request path), so parse it directly.
      final request = LinklanProtocol.pbDecode(
        LinklanProtocol.openChannel(LinklanProtocol.isdrAid),
      );
      expect(request[1], LinklanProtocol.scardOpen);
      final params = LinklanProtocol.pbDecode(
        LinklanProtocol.pbBytesOf(request, 2)!,
      );
      final aid = LinklanProtocol.pbBytesOf(params, 1)!;
      expect(aid.length, 32); // "A0000005591010…" as text
      expect(utf8.decode(aid), LinklanProtocol.isdrAid);
    });

    test('password records round-trip and follow a rename', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await LinklanAdapter.savePasswordForDevice(
        previousDeviceName: '',
        deviceName: 'BLE-eSIM-63129168',
        password: 'demo-card-pw',
      );
      await LinklanAdapter.savePasswordForDevice(
        previousDeviceName: '',
        deviceName: 'BLE-eSIM-00000001',
        password: 'demo-card-pw-2',
      );
      final stored = await LinklanAdapter.loadStoredPasswords();
      expect(stored.map((r) => r.deviceName).toList(), [
        'BLE-eSIM-00000001',
        'BLE-eSIM-63129168',
      ]);

      // A name change keeps one record, not two.
      await LinklanAdapter.savePasswordForDevice(
        previousDeviceName: 'BLE-eSIM-63129168',
        deviceName: 'BLE-eSIM-63129168|v2',
        password: 'demo-card-pw',
      );
      final afterRename = await LinklanAdapter.loadStoredPasswords();
      expect(afterRename.map((r) => r.deviceName).toList(), [
        'BLE-eSIM-00000001',
        'BLE-eSIM-63129168',
      ]);
    });

    test('frames survive a notification split inside the length prefix', () {
      // 0006 0800 1202 0801 is one frame; the first notification ends mid-prefix.
      final assembler = LinklanFrameAssembler();
      expect(assembler.add(<int>[0x00]), isEmpty);
      final first = assembler.add(<int>[
        0x06,
        0x08,
        0x00,
        0x12,
        0x02,
        0x08,
        0x01,
      ]);
      expect(first.length, 1);
      expect(
        LinklanProtocol.bytesToHex(first.single),
        '080012020801'.toUpperCase(),
      );

      // Two frames in one notification, then one byte of the next prefix.
      final second = assembler.add(<int>[
        0x00,
        0x03,
        0xAA,
        0x00,
        0x01,
        0x00,
        0x01,
        0xBB,
        0x00,
      ]);
      expect(second.map(LinklanProtocol.bytesToHex).toList(), ['AA0001', 'BB']);
    });

    test('a byte-count frame delivery matches what the card sends', () {
      final assembler = LinklanFrameAssembler();
      expect(assembler.add(<int>[0x00, 0x02, 0x90, 0x00]).single, <int>[
        0x90,
        0x00,
      ]);
    });

    test('a failed openChannel reply is handed back, not thrown', () {
      // SmartCardRsp{1: cmd (omitted), 2: result=1} - the table is full.
      final full = Uint8List.fromList(<int>[0x10, 0x01]);
      final parsed = LinklanAdapter.parseOpenChannelRsp(full);
      expect(parsed.result, 1);
      expect(parsed.channel, 0);
      expect(parsed.candidates, isEmpty);

      // A successful reply carries OpenChannelRsp{1: packed 02} = channel 1.
      final ok = Uint8List.fromList(<int>[0x1A, 0x03, 0x0A, 0x01, 0x02]);
      final success = LinklanAdapter.parseOpenChannelRsp(ok);
      expect(success.result, 0);
      expect(success.channel, 1);
      expect(success.candidates, <int>[1, 2]);
    });

    test('AUTH frame has exactly one field-2 wrapper', () {
      // The bug this pins: {1:3, 2:{2:{3:…}}} made the card answer with a fresh
      // challenge, which looks exactly like a wrong password.
      final frame = LinklanProtocol.authFrame(
        hex('00112233445566778899aabbccddeeff'),
        hex('11' * 32),
      );
      expect(
        LinklanProtocol.bytesToHex(frame).toLowerCase(),
        '080312381a3612340a10'
        '00112233445566778899aabbccddeeff'
        '1220'
        '${'11' * 32}',
      );
    });

    test('UPDATE proof rejects a wrong password', () {
      final psk = LinklanProtocol.pskFromPassword('demo-card-pw');
      final mac = LinklanProtocol.sessionMac(
        psk,
        hex('00112233445566778899aabbccddeeff'),
        hex('ff' * 16),
      );
      final nonce = hex('0102030405060708090a0b0c');
      final aad = hex('10' * 16);
      final good = LinklanProtocol.authProof(
        mac,
        LinklanProtocol.concatAll([nonce, aad]),
      );
      expect(LinklanProtocol.verifyUpdateProof(mac, nonce, aad, good), isTrue);
      expect(
        LinklanProtocol.verifyUpdateProof(
          mac,
          nonce,
          aad,
          Uint8List.fromList(List<int>.filled(32, 7)),
        ),
        isFalse,
      );
      expect(
        LinklanProtocol.verifyUpdateProof(mac, nonce, aad, Uint8List(0)),
        isFalse,
      );
      // A missing optional field is not the same as a present, empty proof.
      expect(LinklanProtocol.verifyUpdateProof(mac, nonce, aad, null), isTrue);
    });

    test('STORE DATA splits at 255 bytes with 11/91 and the block index', () {
      final one = LinklanProtocol.storeDataBlocks(Uint8List(255));
      expect(one.length, 1);
      expect(one.single.p1, 0x91);
      expect(one.single.p2, 0);

      final two = LinklanProtocol.storeDataBlocks(Uint8List(256));
      expect(two.length, 2);
      expect(two[0].p1, 0x11);
      expect(two[0].chunk.length, 255);
      expect(two[1].p1, 0x91);
      expect(two[1].p2, 1);
      expect(two[1].chunk.length, 1);

      final four = LinklanProtocol.storeDataBlocks(Uint8List(834));
      expect(four.length, 4);
      expect(four.map((b) => b.p1).toList(), [0x11, 0x11, 0x11, 0x91]);
      expect(four.map((b) => b.p2).toList(), [0, 1, 2, 3]);
      expect(four.fold<int>(0, (n, b) => n + b.chunk.length), 834);
    });

    test('GET RESPONSE is CLA 0x00 INS 0xC0 with Le in P3 and no data', () {
      final payload = LinklanProtocol.transmitApdu(
        channel: 2,
        cla: 0x00,
        ins: 0xc0,
        p1: 0,
        p2: 0,
        data: Uint8List(0),
        p3: 16,
      );
      final req = LinklanProtocol.pbDecode(payload);
      final tai = LinklanProtocol.pbDecode(LinklanProtocol.pbBytesOf(req, 4)!);
      // CLA 0 zigzags to 0, which protobuf omits entirely.
      expect(tai[2], isNull);
      expect(tai[3], LinklanProtocol.zigzag(0xc0)); // ins
      expect(tai[6], LinklanProtocol.zigzag(16)); // P3 = Le
      expect(LinklanProtocol.pbBytesOf(tai, 7), isNull);
    });

    test('continuation status words ask for the right action', () {
      // 61 00 after a 768-byte cut: more follows, length still unknown.
      expect(LinklanAdapter.classifyContinuation(0x6100).kind, 'more');
      // 61 20: 32 more bytes available.
      expect(LinklanAdapter.classifyContinuation(0x6120).length, 0x20);
      // 6C 20: the card wants the same command re-issued with Le=0x20.
      final corrected = LinklanAdapter.classifyContinuation(0x6c20);
      expect(corrected.kind, 'correctedLe');
      expect(corrected.length, 0x20);
      // Unusable channel or command.
      expect(LinklanAdapter.classifyContinuation(0x6d00).kind, 'refused');
      expect(LinklanAdapter.classifyContinuation(0x6881).kind, 'refused');
      // Anything else is the final status, including SW 91xx.
      expect(LinklanAdapter.classifyContinuation(0x9000).kind, 'final');
      expect(LinklanAdapter.classifyContinuation(0x910b).kind, 'final');
    });

    test('openChannel reply channel is a zigzag sint32', () {
      // SmartCardRsp{3: OpenChannelRsp{1: packed sint32}} — wire 02 means 1.
      expect(LinklanAdapter.channelFromOpenChannelRsp(hex('02')), 1);
      expect(LinklanAdapter.channelFromOpenChannelRsp(hex('04')), 2);
      expect(LinklanAdapter.channelFromOpenChannelRsp(hex('06')), 3);
      expect(LinklanAdapter.channelFromOpenChannelRsp(hex('0402')), 2);
      expect(LinklanAdapter.channelFromOpenChannelRsp(null), 0);
    });

    test('nonce carry propagates past the low byte', () {
      // q4.java adds the counter at byte 11 and carries upwards.
      final base = hex('00112233445566778899aaffff');
      expect(
        LinklanProtocol.bytesToHex(
          LinklanProtocol.nonceFor(base, 1),
        ).toLowerCase(),
        '00112233445566778899ab0000',
      );
      expect(
        LinklanProtocol.bytesToHex(
          LinklanProtocol.nonceFor(base, 0x101),
        ).toLowerCase(),
        '00112233445566778899ab0100',
      );
    });

    test('nonce advances by one', () {
      final nonce = LinklanProtocol.nonceFor(
        hex('e259ee4a1d99e17c6c878441'),
        1,
      );
      expect(
        LinklanProtocol.bytesToHex(nonce).toLowerCase(),
        'e259ee4a1d99e17c6c878442',
      );
    });
  });

  group('Linklan adapter over GATT', () {
    late _TestAdapter adapter;
    late _Card card;
    late Reader reader;
    setUp(() {
      card = _Card();
      adapter = _TestAdapter(card);
      reader = Reader(id: 'ble|test', name: 'BLE-eSIM-test', source: adapter);
      SharedPreferences.setMockInitialValues({
        LinklanAdapter.storedPasswordKey(reader.name): _password,
      });
    });
    Future<Channel> connect() async {
      await adapter.connect(reader);
      return adapter.openChannel();
    }

    test(
      'rejects a command-only writer before asking for a password',
      () async {
        card.hasAckWriter = false;
        await expectLater(
          adapter.connect(reader),
          throwsA(
            _error(AppErrorCode.ERROR_BLUETOOTH_CHARACTERISTIC_NOT_FOUND),
          ),
        );
        expect(card.writes, isEmpty);
        expect(adapter.connectedReader, isNull);
        expect(card.disconnects, 1);
      },
    );

    test('selects an ACK-capable alternative and respects the MTU', () async {
      final channel = await connect();
      await channel.transmit(0x80, 0xe2, 0x91, 0, Uint8List(255));
      expect(card.writes, contains(180));
      card.reportedMtu = 23;
      card.writes.clear();
      await channel.transmit(0x80, 0xe2, 0x91, 0, Uint8List(100));
      expect(card.writes, everyElement(lessThanOrEqualTo(20)));
      await adapter.disconnect();
      expect(await adapter.listReaders(), isEmpty);
      expect(adapter.password, isNull);
    });

    for (final sw in [0x6881, 0x6d00]) {
      test('caller-split STORE DATA propagates $sw without replay', () async {
        final channel = await connect();
        card.apdus.clear();
        card.reply = (a) => (a.p2 == 1 ? sw : 0x9000, []);
        await channel.transmit(0x80, 0xe2, 0x11, 0, Uint8List(120));
        expect(await channel.transmit(0x80, 0xe2, 0x91, 1, Uint8List(40)), [
          sw >> 8,
          sw & 255,
        ]);
        expect(card.opens, 1);
        expect(card.apdus.map((a) => (a.channel, a.p2)), [(2, 0), (2, 1)]);
        await expectLater(
          channel.transmit(0x80, 0xe2, 0x91, 2, Uint8List(3)),
          throwsA(_error(AppErrorCode.ERROR_TRANSACTION_FAILED)),
        );
        expect(card.apdus, hasLength(2));
      });
    }

    test(
      'adapter-split STORE DATA stops on the rejected middle block',
      () async {
        final channel = await connect();
        card.apdus.clear();
        card.reply = (a) => (a.p2 == 1 ? 0x6881 : 0x9000, []);
        expect(await channel.transmit(0x80, 0xe2, 0x91, 0, Uint8List(600)), [
          0x68,
          0x81,
        ]);
        expect(card.apdus.map((a) => (a.channel, a.p1, a.p2)), [
          (2, 0x11, 0),
          (2, 0x11, 1),
        ]);
        expect(card.opens, 1);
      },
    );

    for (final correctedLe in [0x20, 0x00]) {
      test(
        '61xx -> 6Cxx retries the wire Le on the serving channel ($correctedLe)',
        () async {
          final channel = await connect();
          card.apdus.clear();
          final replies = <(int, List<int>)>[
            (0x6100, [0xaa]),
            (0x6e00, []),
            (0x6c00 | correctedLe, [0xee]),
            (0x6101, [0xbb]),
            (0x910b, [0xcc]),
          ].iterator;
          card.reply = (_) {
            expect(replies.moveNext(), isTrue);
            return replies.current;
          };
          expect(await channel.transmit(0x80, 0xe2, 0x91, 0, hex('01')), [
            0xaa,
            0xbb,
            0xcc,
            0x90,
            0,
          ]);
          expect(card.apdus.skip(1).map((a) => (a.ins, a.channel, a.p3)), [
            (0xc0, 2, 0),
            (0xc0, 1, 0),
            (0xc0, 1, correctedLe),
            (0xc0, 1, 1),
          ]);
          expect(channel.channelNumber, 0);
        },
      );
    }

    test(
      'an explicit probe refusal may try another channel on the same link',
      () async {
        card.reply = (a) => (a.channel == 2 ? 0x6881 : 0x9000, []);
        expect((await connect()).channelNumber, 4);
        expect(card.apdus.map((a) => a.channel), [2, 4]);
        expect(card.disconnects, 0);
      },
    );

    test(
      'a refused probe releases its allocation before the next open',
      () async {
        await adapter.connect(reader);
        card.reply = (_) => (0x6881, []);
        await expectLater(
          adapter.openChannel(),
          throwsA(_error(AppErrorCode.ERROR_CHANNEL_OPEN_FAILED)),
        );
        expect(card.opens, 1);
        expect(card.closes, 1);
        expect(card.disconnects, 0);
        card.reply = (_) => (0x9000, []);
        expect((await adapter.openChannel()).channelNumber, 2);
      },
    );

    test(
      'refused continuations fail rather than returning partial data',
      () async {
        final channel = await connect();
        card.apdus.clear();
        card.reply = (a) => a.ins == 0xc0 ? (0x6d00, []) : (0x6100, [0xab]);
        await expectLater(
          channel.transmit(0x80, 0xe2, 0x91, 0, hex('01')),
          throwsA(_error(AppErrorCode.ERROR_TRANSACTION_FAILED)),
        );
        expect(card.apdus.skip(1).map((a) => a.channel), [2, 1, 0]);
        expect(adapter.connectedReader, isNull);
      },
    );

    testWidgets('interrupt wakes a short APDU during the refresh delay', (
      tester,
    ) async {
      final channel = await connect();
      card.reply = (_) => (0x910b, []);
      await channel.transmit(0x80, 0xe2, 0x91, 0, hex('01'));
      final writes = card.writes.length;
      final pending = expectLater(
        channel.transmit(0x80, 0xe2, 0x91, 0, hex('02')),
        throwsA(_error(AppErrorCode.ERROR_BLUETOOTH_TIMEOUT)),
      );
      await tester.pump();
      adapter.interruptPendingOperation();
      await tester.pump();
      await pending;
      expect(adapter.isExclusivelyBusy, isFalse);
      await tester.pump(const Duration(seconds: 9));
      expect(card.writes, hasLength(writes));
      expect(card.opens, 1);
    });

    testWidgets(
      'interrupt dismisses only its password dialog and releases the lock',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(),
          ),
        );
        final pending = expectLater(
          adapter.runExclusive(() async {
            final channel = await connect();
            await channel.transmit(0x80, 0xe2, 0x91, 0, hex('02'));
          }),
          throwsA(_error(AppErrorCode.ERROR_BLUETOOTH_TIMEOUT)),
        );
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsOneWidget);
        final other = DialogRoute<void>(
          context: navigatorKey.currentContext!,
          builder: (_) => const AlertDialog(title: Text('Other route')),
        );
        unawaited(navigatorKey.currentState!.push(other));
        await tester.pumpAndSettle();
        adapter.interruptPendingOperation();
        await tester.pumpAndSettle();
        await pending;
        expect(other.isCurrent, isTrue);
        expect(find.byType(TextField, skipOffstage: false), findsNothing);
        expect(card.writes, isEmpty);
        expect(adapter.isExclusivelyBusy, isFalse);
        expect(await LinklanAdapter.loadStoredPasswords(), isEmpty);
        await LinklanAdapter.savePasswordForDevice(
          previousDeviceName: '',
          deviceName: reader.name,
          password: _password,
        );
        await connect();
        expect(adapter.connectedReader, reader);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets('a rejected password is replaced only after authentication', (
      tester,
    ) async {
      final passwordKey = LinklanAdapter.storedPasswordKey(reader.name);
      SharedPreferences.setMockInitialValues({
        passwordKey: 'wrong-test-password',
      });
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(),
        ),
      );
      final pending = adapter.connect(reader);
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(passwordKey), 'wrong-test-password');
      await tester.enterText(find.byType(TextField), _password);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await pending;
      expect(find.byType(AlertDialog), findsNothing);
      expect(adapter.password, _password);
      expect(prefs.getString(passwordKey), _password);
    });

    testWidgets(
      'reset waits for the card without sending CLOSE into the reset',
      (tester) async {
        await connect();
        final reset = adapter.resetAfterProfileSwitch();
        await tester.pump();
        expect(card.resets, 1);
        expect(card.closes, 0);
        await tester.pump(const Duration(seconds: 9));
        await reset;
        expect((await adapter.openChannel()).channelNumber, 2);
        expect(card.closes, 0);
      },
    );

    testWidgets('interrupt during a write never sends the next chunk', (
      tester,
    ) async {
      final channel = await connect();
      final ack = card.holdNextWrite = Completer<void>();
      card.writes.clear();
      final pending = expectLater(
        channel.transmit(0x80, 0xe2, 0x91, 0, Uint8List(200)),
        throwsA(_error(AppErrorCode.ERROR_BLUETOOTH_TIMEOUT)),
      );
      await tester.pump();
      expect(card.writes, [180]);
      adapter.interruptPendingOperation();
      await tester.pump();
      await pending;
      ack.complete();
      await tester.pump();
      expect(card.writes, [180]);
      expect(card.disconnects, 1);
      await connect();
      final writes = card.writes.length;
      await expectLater(
        channel.transmit(0x80, 0xe2, 0x91, 0),
        throwsA(_error(AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED)),
      );
      expect(card.writes.length, writes);
    });

    for (final probe in [true, false]) {
      testWidgets(
        'a late ${probe ? "probe" : "GET RESPONSE"} reply cannot serve another request',
        (tester) async {
          await adapter.connect(reader);
          final channel = probe ? null : await adapter.openChannel();
          card.apdus.clear();
          card.reply = (a) {
            if (!probe && a.ins != 0xc0) return (0x6100, [1]);
            card.deferReply = true;
            return (0x9000, [2]);
          };
          final pending = expectLater(
            channel == null
                ? adapter.openChannel()
                : channel.transmit(0x80, 0xe2, 0x91, 0, hex('01')),
            throwsA(_error(AppErrorCode.ERROR_BLUETOOTH_TIMEOUT)),
          );
          await tester.pump();
          await tester.pump(Duration(seconds: probe ? 5 : 3));
          await pending;
          expect(card.disconnects, 1);
          expect(card.apdus.map((a) => a.channel), probe ? [2] : [2, 2]);
          card.notifications.add(card.lateReply!);
          await tester.pump();
          await expectLater(
            adapter.openChannel(),
            throwsA(_error(AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED)),
          );
          card.reply = (_) => (0x9000, []);
          expect((await connect()).channelNumber, 2);
        },
      );
    }

    test(
      'AID restrictions and raw access fail without sending an APDU',
      () async {
        await adapter.connect(reader);
        final writes = card.writes.length;
        await expectLater(
          adapter.openChannel(aids: ['0000']),
          throwsA(_error(AppErrorCode.ERROR_APPLICATION_NOT_FOUND)),
        );
        await expectLater(
          adapter.sendRawApdu(hex('00a40000')),
          throwsUnsupportedError,
        );
        expect(card.writes.length, writes);
        final channel = await adapter.openChannel(
          aids: ['0000', LinklanProtocol.isdrAid.toLowerCase()],
        );
        expect(channel.aid, LinklanProtocol.isdrAid);
        final count = card.apdus.length;
        await expectLater(
          channel.transmit(0, 0xa4, 4, 0, hex('1122'), 0),
          throwsUnsupportedError,
        );
        expect(card.apdus.length, count);
      },
    );
  });
}

const _password = 'demo-card-pw';
Matcher _error(AppErrorCode code) =>
    isA<AppException>().having((e) => e.code, 'code', code);

typedef _Apdu = ({int channel, int ins, int p1, int p2, int p3});

class _TestAdapter extends LinklanAdapter {
  _TestAdapter(this.card);
  final _Card card;
  @override
  Future<BluetoothDevice> openBleDevice(String deviceId) async => card;
}

class _Service extends Fake implements BluetoothService {
  _Service(this.characteristics);
  @override
  final List<BluetoothCharacteristic> characteristics;
  @override
  Guid get uuid => Guid(LinklanProtocol.serviceUuid);
}

class _Characteristic extends Fake implements BluetoothCharacteristic {
  _Characteristic(String id, this.properties, this.card) : uuid = Guid(id);
  @override
  final Guid uuid;
  @override
  final CharacteristicProperties properties;
  final _Card card;
  @override
  Stream<List<int>> get onValueReceived =>
      (card.notifications = StreamController<List<int>>(
        sync: true,
        onCancel: () async {},
      )).stream;
  @override
  Future<bool> setNotifyValue(
    bool notify, {
    int timeout = 15,
    bool forceIndications = false,
  }) async => true;
  @override
  Future<void> write(
    List<int> value, {
    bool withoutResponse = false,
    bool allowLongWrite = false,
    int timeout = 15,
  }) async {
    if (!properties.write || withoutResponse) {
      throw StateError(
        'Expected a write with response on the ACK-capable characteristic',
      );
    }
    await card.write(value);
  }
}

/// Only the peripheral is fake: the adapter really discovers, authenticates,
/// frames, encrypts, writes and consumes notifications.
class _Card extends Fake implements BluetoothDevice {
  late StreamController<List<int>> notifications;
  final assembler = LinklanFrameAssembler();
  final writes = <int>[];
  final apdus = <_Apdu>[];
  (int, List<int>) Function(_Apdu) reply = (_) => (0x9000, []);
  int opens = 0, closes = 0, resets = 0, disconnects = 0, reportedMtu = 247;
  bool hasAckWriter = true, deferReply = false;
  Uint8List? lateReply;
  Completer<void>? holdNextWrite;
  final random = Uint8List(16), base = Uint8List(12), aad = Uint8List(16);
  late Uint8List key;
  @override
  int get mtuNow => reportedMtu;
  StreamController<BluetoothConnectionState>? _connections;
  @override
  Stream<BluetoothConnectionState> get connectionState =>
      (_connections = StreamController<BluetoothConnectionState>(
        sync: true,
        onCancel: () async {},
      )).stream;
  @override
  Future<void> disconnect({
    int timeout = 35,
    bool queue = true,
    int androidDelay = 2000,
  }) async {
    disconnects++;
    assembler.reset();
    _connections?.add(BluetoothConnectionState.disconnected);
  }

  @override
  Future<List<BluetoothService>> discoverServices({
    bool subscribeToServicesChanged = true,
    int timeout = 15,
  }) async => [
    _Service([
      _Characteristic(
        '6e400002-b5a3-f393-e0a9-e50e24dcca9e',
        const CharacteristicProperties(writeWithoutResponse: true),
        this,
      ),
      _Characteristic(
        '6e400003-b5a3-f393-e0a9-e50e24dcca9e',
        const CharacteristicProperties(notify: true),
        this,
      ),
      if (hasAckWriter)
        _Characteristic(
          '6e400004-b5a3-f393-e0a9-e50e24dcca9e',
          const CharacteristicProperties(
            write: true,
            writeWithoutResponse: true,
          ),
          this,
        ),
    ]),
  ];

  Future<void> write(List<int> bytes) async {
    writes.add(bytes.length);
    final hold = holdNextWrite;
    holdNextWrite = null;
    if (hold != null) return hold.future;
    for (final frame in assembler.add(bytes)) {
      final response = LinklanProtocol.withLengthPrefix(answer(frame));
      if (deferReply) {
        lateReply = response;
        deferReply = false;
      } else {
        notifications.add(response);
      }
    }
  }

  Uint8List answer(Uint8List frame) {
    final decode = LinklanProtocol.pbDecode;
    final bytes = LinklanProtocol.pbBytes;
    final join = LinklanProtocol.concatAll;
    final outer = decode(frame);
    if (outer[1] == LinklanProtocol.cmdDevice) {
      return bytes(3, bytes(2, bytes(1, random)));
    }
    if (outer[1] != LinklanProtocol.cmdSecurity) {
      throw StateError('Unexpected unencrypted request');
    }
    final security = decode(outer[2] as Uint8List);
    if (security.containsKey(3)) {
      final auth = decode(decode(security[3] as Uint8List)[2] as Uint8List);
      final cli = auth[1] as Uint8List;
      final mac = LinklanProtocol.sessionMac(
        LinklanProtocol.pskFromPassword(_password),
        random,
        cli,
      );
      if (LinklanProtocol.bytesToHex(auth[2] as Uint8List) !=
          LinklanProtocol.bytesToHex(LinklanProtocol.authProof(mac, cli))) {
        return LinklanProtocol.pbInt(5, 5);
      }
      key = mac.sublist(16);
      return bytes(
        3,
        bytes(
          3,
          join([
            bytes(1, base),
            bytes(2, aad),
            bytes(3, LinklanProtocol.authProof(mac, join([base, aad]))),
          ]),
        ),
      );
    }
    final nonce = LinklanProtocol.nonceFor(base, security[1] as int);
    final request = decode(
      LinklanProtocol.aesCcmDecrypt(key, nonce, aad, security[2] as Uint8List),
    );
    var response = hex('0801');
    if (request[1] == LinklanProtocol.cmdScard) {
      final scard = decode(request[2] as Uint8List);
      if (scard[1] == LinklanProtocol.scardOpen) {
        opens++;
        response = bytes(3, bytes(1, [4])); // channel 2
      } else if (scard[1] == LinklanProtocol.scardClose) {
        closes++;
      } else if (scard[1] == LinklanProtocol.scardTransmit) {
        final fields = decode(scard[4] as Uint8List);
        int field(int n) =>
            LinklanProtocol.unzigzag(LinklanProtocol.pbIntOf(fields, n));
        final apdu = (
          channel: field(1),
          ins: field(3),
          p1: field(4),
          p2: field(5),
          p3: field(6),
        );
        apdus.add(apdu);
        final (sw, body) = reply(apdu);
        response = bytes(
          4,
          join([
            LinklanProtocol.pbInt(1, LinklanProtocol.zigzag(sw >> 8)),
            LinklanProtocol.pbInt(2, LinklanProtocol.zigzag(sw & 255)),
            bytes(3, body),
          ]),
        );
      }
    }
    if (request[1] == LinklanProtocol.cmdDevice &&
        decode(request[2] as Uint8List)[1] == 3) {
      resets++;
    }
    return bytes(2, LinklanProtocol.aesCcmEncrypt(key, nonce, aad, response));
  }
}
