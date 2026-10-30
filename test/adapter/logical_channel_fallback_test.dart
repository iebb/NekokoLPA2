import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:nlpa2/adapter/euicc_adapter.dart';
import 'package:nlpa2/utils/apdu_exception.dart';
import 'package:nlpa2/utils/error_codes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const aid = 'A0000005591010FFFFFFFF8900000100';

  test(
    'WebCard fallback selects and transmits on basic channel after 6881',
    () async {
      final adapter = _Adapter(0x6881);
      final channel = await adapter.openLogicalChannel(
        aids: [aid],
        skipCleanup: true,
      );
      expect(channel.channelNumber, 0);
      expect(channel.aid, aid);
      expect(
        adapter.commands.map((apdu) => apdu.take(4).toList()),
        containsAllInOrder([
          [1, 0xA4, 4, 0],
          [0, 0x70, 0x80, 1],
          [0, 0xA4, 4, 0],
        ]),
      );
      await channel.transmit(0x80, 0xE2, 0x91, 0);
      expect(adapter.commands.last[0], 0x80);
      final count = adapter.commands.length;
      await channel.close();
      expect(
        adapter.commands.length,
        count,
      ); // Never MANAGE CHANNEL-close zero.
    },
  );

  test(
    'logical-channel SELECT remains on its allocated channel when supported',
    () async {
      final adapter = _Adapter(0x9000);
      final channel = await adapter.openLogicalChannel(
        aids: [aid],
        skipCleanup: true,
      );
      expect(channel.channelNumber, 1);
      await channel.transmit(0x80, 0xE2, 0x91, 0);
      expect(adapter.commands.last[0], 0x81);
      await channel.close();
    },
  );

  test('other transports preserve 6881 card-busy recovery behavior', () async {
    final adapter = _Adapter(0x6881, allowBasicFallback: false);
    await expectLater(
      adapter.openLogicalChannel(aids: [aid], skipCleanup: true),
      throwsA(isA<CardBusyException>()),
    );
    expect(adapter.basicSelects, 0);
  });

  for (final status in [0x6985, 0x6999, 0x6A82]) {
    test(
      'WebCard fallback does not bypass SELECT status ${status.toRadixString(16)}',
      () async {
        final adapter = _Adapter(status);
        await expectLater(
          adapter.openLogicalChannel(aids: [aid], skipCleanup: true),
          throwsA(
            status == 0x6A82
                ? isA<AppException>()
                : isA<ConditionOfUseNotSatisfiedException>(),
          ),
        );
        expect(adapter.basicSelects, 0);
      },
    );
  }

  test(
    'an unsupported basic-channel applet still fails after fallback',
    () async {
      final adapter = _Adapter(0x6881, basicStatus: 0x6A82);
      await expectLater(
        adapter.openLogicalChannel(aids: [aid], skipCleanup: true),
        throwsA(isA<AppException>()),
      );
      expect(adapter.basicSelects, 1);
    },
  );
}

class _Adapter extends BaseAdapter {
  _Adapter(
    this.selectStatus, {
    this.basicStatus = 0x9000,
    this.allowBasicFallback = true,
  }) : super(Logger('WebCardFallbackTest'));
  final bool allowBasicFallback;
  @override
  bool get fallbackToBasicChannelOnSelect6881 => allowBasicFallback;
  final int selectStatus;
  final int basicStatus;
  final commands = <Uint8List>[];
  int basicSelects = 0;
  @override
  Stream<EuiccPortState> get stateStream => const Stream.empty();
  @override
  bool get requiresRefresh => false;
  @override
  String? get lastAtr => null;
  @override
  Future<List<Reader>> listReaders({bool force = false}) async => [];
  @override
  Future<void> connect(Reader reader) async {}
  @override
  Future<void> disconnect() async {}
  @override
  Future<Channel> openChannel({List<String>? aids}) =>
      openLogicalChannel(aids: aids);
  @override
  Future<Uint8List> sendRawApdu(Uint8List apdu) async {
    commands.add(apdu);
    if (apdu[1] == 0x70 && apdu[2] == 0) {
      return Uint8List.fromList([1, 0x90, 0]);
    }
    if (apdu[1] == 0xA4) {
      final basic = apdu[0] == 0;
      if (basic) basicSelects++;
      final status = basic ? basicStatus : selectStatus;
      return Uint8List.fromList([status >> 8, status & 0xff]);
    }
    return Uint8List.fromList([0x90, 0]);
  }
}
