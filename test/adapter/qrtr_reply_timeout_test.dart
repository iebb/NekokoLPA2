import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/adapter/qrtr/qrtr_socket.dart';

/// A socket whose replies arrive at set times on a clock the test owns.
class _FakeSocket implements QrtrSocket {
  DateTime now = DateTime(2026);

  /// When the next datagram arrives; null for never.
  DateTime? arrival;
  final List<int> waits = [];

  void replyAfter(Duration delay) => arrival = now.add(delay);

  @override
  Future<QrtrAddress> address() async => const QrtrAddress(1, 0);

  @override
  Future<void> send(QrtrAddress to, Uint8List datagram) async {}

  @override
  Future<QrtrDatagram?> receive(int timeoutMs) async {
    waits.add(timeoutMs);
    final end = now.add(Duration(milliseconds: timeoutMs));
    final at = arrival;
    if (at != null && !at.isAfter(end)) {
      now = at;
      arrival = null;
      return QrtrDatagram(const QrtrAddress(0, 42), Uint8List.fromList([0x90]));
    }
    now = end;
    return null;
  }

  @override
  Future<void> close() async {}
}

void main() {
  const service = QrtrAddress(0, 42);
  const control = QrtrAddress(1, PatientQrtrSocket.controlPort);
  final apdu = Uint8List(4);

  late _FakeSocket inner;
  late PatientQrtrSocket socket;
  setUp(() {
    inner = _FakeSocket();
    socket = PatientQrtrSocket(
      inner,
      replyTimeout: const Duration(seconds: 30),
      now: () => inner.now,
    );
  });

  test('waits past the transport timeout for a slow card', () async {
    await socket.send(service, apdu);
    inner.replyAfter(const Duration(seconds: 7));

    final reply = await socket.receive(2000);
    expect(reply?.data, [0x90]);
    expect(inner.waits, [2000, 2000, 2000, 2000]);
  });

  test('gives up once the reply timeout has passed', () async {
    await socket.send(service, apdu);
    final sent = inner.now;

    expect(await socket.receive(2000), isNull);
    expect(inner.now.difference(sent), const Duration(seconds: 30));
  });

  test(
    'counts the reply timeout from the request, not from each wait',
    () async {
      await socket.send(service, apdu);
      final sent = inner.now;
      inner.replyAfter(const Duration(seconds: 29));
      expect(await socket.receive(2000), isNotNull);

      // A datagram for somebody else must not buy another thirty seconds.
      expect(await socket.receive(2000), isNull);
      expect(inner.now.difference(sent), const Duration(seconds: 30));
    },
  );

  test('a lookup keeps the wait the transport asked for', () async {
    await socket.send(service, apdu);
    await socket.send(control, apdu);

    expect(await socket.receive(2000), isNull);
    expect(inner.waits, [2000]);
  });
}
