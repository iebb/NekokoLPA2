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

/// A socket that gives a service as long to reply as a card can need.
///
/// The QMI transport above waits the same short time for everything: two
/// seconds for the bus to answer a lookup, and two seconds for the modem to
/// answer a request. That is enough for the bus and far too little for a card:
/// an eUICC takes longer than that over a signature or a block of a profile,
/// and a reply given up on is a command the card went on to finish anyway,
/// which leaves a download broken halfway.
///
/// So this keeps asking the socket underneath until [replyTimeout] has passed
/// since the last datagram sent to a service. A lookup, which is addressed to
/// the bus's control port, keeps the wait the transport asked for.
class PatientQrtrSocket implements QrtrSocket {
  PatientQrtrSocket(
    this._inner, {
    required this.replyTimeout,
    DateTime Function() now = DateTime.now,
  }) : _now = now;

  /// `QRTR_PORT_CTRL`: where the bus's name service is asked.
  static const int controlPort = 0xfffffffe;

  final QrtrSocket _inner;
  final DateTime Function() _now;

  /// How long a service has to reply to what was last sent to it.
  final Duration replyTimeout;

  /// When the service last written to has to have replied by, or null while
  /// what is awaited is the bus's own answer.
  DateTime? _replyDeadline;

  @override
  Future<QrtrAddress> address() => _inner.address();

  @override
  Future<void> send(QrtrAddress to, Uint8List datagram) {
    _replyDeadline = to.port == controlPort ? null : _now().add(replyTimeout);

    return _inner.send(to, datagram);
  }

  @override
  Future<QrtrDatagram?> receive(int timeoutMs) async {
    final deadline = _replyDeadline;
    if (deadline == null) return _inner.receive(timeoutMs);

    // Short waits one after another, rather than one long one, so the process
    // holding the socket is never asked to block for the whole of it.
    final step = timeoutMs < 1 ? 1 : timeoutMs;
    while (true) {
      final remaining = deadline.difference(_now()).inMilliseconds;
      if (remaining <= 0) return null;

      final datagram = await _inner.receive(
        remaining < step ? remaining : step,
      );
      if (datagram != null) return datagram;
    }
  }

  @override
  Future<void> close() => _inner.close();
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
