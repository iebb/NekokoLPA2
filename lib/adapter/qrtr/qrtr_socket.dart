import 'dart:io' show Platform;
import 'dart:typed_data';

import 'qrtr_host.dart';

/// Where on the bus a datagram is going, or came from: a node and a port.
class QrtrAddress {
  const QrtrAddress(this.node, this.port);

  final int node;
  final int port;
}

/// One datagram, and where it came from.
class QrtrDatagram {
  const QrtrDatagram(this.from, this.data);

  final QrtrAddress from;
  final Uint8List data;
}

/// A datagram socket to the modem's bus.
///
/// This is the one thing a QMI transport needs from the link, so it is the one
/// thing a platform has to provide. On Linux the app opens the socket itself;
/// on Android it may not open one at all — SELinux refuses it the socket and
/// refuses it the use of one another process opened — so the socket stays in
/// the process Shizuku runs and this asks that process instead.
abstract class QrtrSocket {
  /// The address this socket sends from, which is where a lookup starts.
  Future<QrtrAddress> address();

  /// Send one datagram to an address on the bus.
  Future<void> send(QrtrAddress to, Uint8List datagram);

  /// Wait for one datagram, or give up after `timeoutMs`.
  Future<QrtrDatagram?> receive(int timeoutMs);

  /// Let the socket go.
  Future<void> close();
}

/// Open a socket to the bus, by whichever door this platform has.
Future<QrtrSocket> openQrtrSocket() async {
  if (Platform.isAndroid) {
    return QrtrHostSocket(await QrtrHost.openBus());
  }

  throw UnsupportedError('QRTR is only reachable on Android');
}

/// The socket in the process Shizuku runs, reached a datagram at a time.
class QrtrHostSocket implements QrtrSocket {
  QrtrHostSocket(this._bus);

  final int _bus;

  @override
  Future<QrtrAddress> address() async =>
      QrtrAddress(await QrtrHost.node(_bus), 0);

  @override
  Future<void> send(QrtrAddress to, Uint8List datagram) =>
      QrtrHost.send(_bus, to.node, to.port, datagram);

  @override
  Future<QrtrDatagram?> receive(int timeoutMs) async {
    final packet = await QrtrHost.receive(_bus, timeoutMs);
    if (packet == null) return null;

    // The address it came from is in front of the message: node then port,
    // both 32 bit little endian.
    final header = ByteData.sublistView(packet);

    return QrtrDatagram(
      QrtrAddress(
        header.getUint32(0, Endian.little),
        header.getUint32(4, Endian.little),
      ),
      packet.sublist(8),
    );
  }

  @override
  Future<void> close() => QrtrHost.closeBus(_bus);
}
