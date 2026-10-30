import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/adapter/euicc_adapter.dart';
import 'package:nlpa2/adapter/omapi/omapi_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const native = MethodChannel('ee.nekoko.omapi_plugin');
  const aid = 'A0000005591010FFFFFFFF8900000100';
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late OmapiAdapter adapter;
  late int closes;
  late int opens;
  setUp(() async {
    closes = 0;
    opens = 0;
    messenger.setMockMethodCallHandler(native, (call) async {
      switch (call.method) {
        case 'connect':
          return {'success': true, 'atr': ''};
        case 'openChannel':
          opens++;
          return {'success': true, 'aid': aid};
        case 'closeChannel':
          closes++;
          return true;
        case 'transmitOnChannel':
          return '9000';
        default:
          return true;
      }
    });
    adapter = OmapiAdapter();
    await adapter.connect(
      Reader(id: 'omapi:SIM1', name: 'SIM 1', source: adapter),
    );
  });
  tearDown(() async {
    await adapter.disconnect();
    messenger.setMockMethodCallHandler(native, null);
  });
  test(
    'background flushes the three-second released-channel cache immediately',
    () async {
      final channel = await adapter.openChannel(aids: [aid]);
      await channel.close();
      expect(closes, 0);
      await adapter.setAppInBackground(true);
      expect(closes, 1);
      expect(opens, 1);
    },
  );
  test(
    'a background operation keeps its live handle until it releases it',
    () async {
      final channel = await adapter.openChannel(aids: [aid]);
      await adapter.setAppInBackground(true);
      expect(closes, 0);
      await channel.transmit(0, 0xCA, 0, 0);
      await channel.close();
      expect(closes, 1);
    },
  );
  test(
    'a borrowed cached channel is not closed by background cleanup',
    () async {
      final first = await adapter.openChannel(aids: [aid]);
      await first.close();
      final borrowed = await adapter.openChannel(aids: [aid]);
      await adapter.setAppInBackground(true);
      expect(closes, 0);
      expect(opens, 1);
      await borrowed.close();
      expect(closes, 1);
    },
  );
  test(
    'foreground retains channel reuse after returning from background',
    () async {
      await adapter.setAppInBackground(true);
      await adapter.setAppInBackground(false);
      final first = await adapter.openChannel(aids: [aid]);
      await first.close();
      final next = await adapter.openChannel(aids: [aid]);
      expect(opens, 1);
      expect(closes, 0);
      await next.close();
      await adapter.setAppInBackground(true);
      expect(closes, 1);
    },
  );
  test(
    'queued background close rechecks ownership after a handle is borrowed',
    () async {
      final first = await adapter.openChannel(aids: [aid]);
      await first.close();
      final entered = Completer<void>();
      final borrow = Completer<void>();
      final borrowed = Completer<Channel>();
      final release = Completer<void>();
      final busy = adapter.runExclusive(() async {
        entered.complete();
        await borrow.future;
        borrowed.complete(await adapter.openChannel(aids: [aid]));
        await release.future;
      });
      await entered.future;
      final flushing = adapter.setAppInBackground(true);
      borrow.complete();
      final live = await borrowed.future;
      release.complete();
      await busy;
      await flushing;
      expect(closes, 0);
      await live.transmit(0, 0xCA, 0, 0);
      await live.close();
      expect(closes, 1);
    },
  );
}
