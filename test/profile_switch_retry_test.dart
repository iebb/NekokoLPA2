import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:nlpa2/adapter/euicc_adapter.dart';
import 'package:nlpa2/logic/profile_manager.dart';
import 'package:nlpa2/utils/apdu_exception.dart';

void main() {
  test('ambiguous enable is submitted only once', () async {
    final adapter = _FakeAdapter();
    final channel = _FakeChannel(adapter, () {
      throw CardBusyException('6881 after enable submission');
    });

    await expectLater(
      ProfileManager(
        adapter,
      ).enableProfile('8901000000000000000', useChannel: channel),
      throwsA(isA<CardBusyException>()),
    );

    expect(channel.transmitCalls, 1);
  });

  test('ambiguous disable is submitted only once', () async {
    final adapter = _FakeAdapter();
    final channel = _FakeChannel(adapter, () {
      throw CardBusyException('6881 after disable submission');
    });

    await expectLater(
      ProfileManager(
        adapter,
      ).disableProfile('8901000000000000000', useChannel: channel),
      throwsA(isA<CardBusyException>()),
    );

    expect(channel.transmitCalls, 1);
  });

  test(
    'pre-submission failure still retries and clears switch marker',
    () async {
      final adapter = _FakeAdapter(
        openChannelBehavior: (attempt) async {
          if (attempt == 1) {
            throw CardBusyException('6881 while opening channel');
          }
          throw const FormatException('stop after proving the retry');
        },
      );

      await expectLater(
        ProfileManager(adapter).enableProfile('8901000000000000000'),
        throwsA(isA<FormatException>()),
      );

      expect(adapter.openChannelCalls, 2);
      expect(adapter.switchMarkerValues, [true, false]);
    },
  );
}

class _FakeAdapter extends BaseAdapter {
  _FakeAdapter({this.openChannelBehavior}) : super(Logger('_FakeAdapter'));

  final Future<Channel> Function(int attempt)? openChannelBehavior;
  final List<bool> switchMarkerValues = [];
  int openChannelCalls = 0;

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
  Future<Channel> openChannel({List<String>? aids}) async {
    openChannelCalls++;
    final implementation = openChannelBehavior;
    if (implementation != null) return implementation(openChannelCalls);
    throw StateError('openChannel was not configured');
  }

  @override
  Future<Uint8List> sendRawApdu(Uint8List apdu) async {
    throw StateError('sendRawApdu should not be called');
  }

  @override
  Future<void> setProfileSwitchInProgress(bool value) async {
    switchMarkerValues.add(value);
  }
}

class _FakeChannel implements Channel {
  _FakeChannel(this.adapter, this._transmit);

  @override
  final Adapter adapter;
  final Uint8List Function() _transmit;
  int transmitCalls = 0;

  @override
  String? get aid => 'A0000005591010FFFFFFFF8900000100';

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
  ]) async {
    transmitCalls++;
    return _transmit();
  }
}
