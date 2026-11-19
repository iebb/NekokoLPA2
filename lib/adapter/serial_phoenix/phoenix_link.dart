import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

/// Raised when the Phoenix link cannot complete a card transaction.
class PhoenixException implements Exception {
  final String message;
  PhoenixException(this.message);

  @override
  String toString() => 'PhoenixException: $message';
}

/// Win32 serial port wrapper (COMx, 8E2, manual RTS/DTR).
///
/// The Phoenix reader is a passive level shifter: the card clock and the ISO
/// 7816 framing are produced by this process, and RST is wired to RTS.
class _Win32Serial {
  static final DynamicLibrary _k32 = DynamicLibrary.open('kernel32.dll');

  static final int Function(Pointer<Utf16>, int, int, Pointer<Void>, int, int, int)
      _createFileW = _k32
          .lookupFunction<
              IntPtr Function(Pointer<Utf16>, Uint32, Uint32, Pointer<Void>,
                  Uint32, Uint32, IntPtr),
              int Function(Pointer<Utf16>, int, int, Pointer<Void>, int, int,
                  int)>('CreateFileW');

  static final int Function(int) _closeHandle =
      _k32.lookupFunction<Int32 Function(IntPtr), int Function(int)>(
          'CloseHandle');

  static final int Function(int, Pointer<Uint8>) _setCommState = _k32
      .lookupFunction<Int32 Function(IntPtr, Pointer<Uint8>),
          int Function(int, Pointer<Uint8>)>('SetCommState');

  static final int Function(int, Pointer<Uint8>) _setCommTimeouts = _k32
      .lookupFunction<Int32 Function(IntPtr, Pointer<Uint8>),
          int Function(int, Pointer<Uint8>)>('SetCommTimeouts');

  static final int Function(int, int) _purgeComm =
      _k32.lookupFunction<Int32 Function(IntPtr, Uint32), int Function(int, int)>(
          'PurgeComm');

  static final int Function(int, int) _escapeCommFunction = _k32
      .lookupFunction<Int32 Function(IntPtr, Uint32), int Function(int, int)>(
          'EscapeCommFunction');

  static final int Function(int, Pointer<Uint8>, int, Pointer<Uint32>, Pointer<Void>)
      _readFile = _k32.lookupFunction<
          Int32 Function(IntPtr, Pointer<Uint8>, Uint32, Pointer<Uint32>,
              Pointer<Void>),
          int Function(int, Pointer<Uint8>, int, Pointer<Uint32>,
              Pointer<Void>)>('ReadFile');

  static final int Function(int, Pointer<Uint8>, int, Pointer<Uint32>, Pointer<Void>)
      _writeFile = _k32.lookupFunction<
          Int32 Function(IntPtr, Pointer<Uint8>, Uint32, Pointer<Uint32>,
              Pointer<Void>),
          int Function(int, Pointer<Uint8>, int, Pointer<Uint32>,
              Pointer<Void>)>('WriteFile');

  static final int Function(Pointer<Utf16>, Pointer<Utf16>, int) _queryDosDeviceW =
      _k32.lookupFunction<
          Uint32 Function(Pointer<Utf16>, Pointer<Utf16>, Uint32),
          int Function(Pointer<Utf16>, Pointer<Utf16>, int)>('QueryDosDeviceW');

  static final RegExp _comPattern = RegExp(r'^COM\d+$');

  /// COM ports present on the system, straight from the object-manager
  /// namespace. Unlike an open-probe this also reports ports that another
  /// process currently holds open.
  static List<String> comPorts() {
    const int bufChars = 65536;
    final raw = calloc<Uint16>(bufChars);
    try {
      final len = _queryDosDeviceW(nullptr, raw.cast<Utf16>(), bufChars);
      if (len == 0) return const [];
      final units = raw.asTypedList(len);
      final out = <String>[];
      var start = 0;
      for (var i = 0; i < len; i++) {
        if (units[i] != 0) continue;
        if (i > start) {
          final name = String.fromCharCodes(units, start, i);
          if (_comPattern.hasMatch(name)) out.add(name);
        }
        start = i + 1;
      }
      return out;
    } catch (_) {
      return const [];
    } finally {
      calloc.free(raw);
    }
  }

  static const int _genericRead = 0x80000000;
  static const int _genericWrite = 0x40000000;
  static const int _openExisting = 3;

  static const int _purgeTxClear = 0x0004;
  static const int _purgeRxClear = 0x0008;

  static const int _setRts = 3;
  static const int _clrRts = 4;
  static const int _setDtr = 5;
  static const int _clrDtr = 6;

  final int _handle;
  final Pointer<Uint32> _readCount = calloc<Uint32>();
  final Pointer<Uint32> _writeCount = calloc<Uint32>();
  final Pointer<Uint8> _buf = calloc<Uint8>(512);

  _Win32Serial._(this._handle);

  static _Win32Serial? tryOpen(String portName, {int baud = 19200}) {
    final path = '\\\\.\\$portName'.toNativeUtf16();
    final handle = _createFileW(
      path,
      _genericRead | _genericWrite,
      0,
      nullptr,
      _openExisting,
      0,
      0,
    );
    calloc.free(path);

    if (handle == -1) return null;

    final self = _Win32Serial._(handle);
    if (!self._configure(baud)) {
      self.close();
      return null;
    }
    return self;
  }

  bool _configure(int baud) {
    // DCB is 28 bytes; bitfield flags are written by hand to avoid layout
    // assumptions. fBinary=1, everything else 0 (DTR/RTS driven manually).
    final dcb = calloc<Uint8>(28);
    final bytes = dcb.asTypedList(28);
    final view = ByteData.view(bytes.buffer, bytes.offsetInBytes, 28);
    view.setUint32(0, 28, Endian.little); // DCBlength
    view.setUint32(4, baud, Endian.little); // BaudRate
    view.setUint32(8, 0x00000001, Endian.little); // fBinary
    view.setUint16(12, 0, Endian.little); // wReserved
    view.setUint16(14, 2048, Endian.little); // XonLim
    view.setUint16(16, 512, Endian.little); // XoffLim
    view.setUint8(18, 8); // ByteSize
    view.setUint8(19, 2); // Parity: EVENPARITY
    view.setUint8(20, 2); // StopBits: TWOSTOPBITS
    view.setUint8(21, 0x11); // XonChar
    view.setUint8(22, 0x13); // XoffChar
    view.setUint8(23, 0); // ErrorChar
    view.setUint8(24, 0); // EofChar
    view.setUint8(25, 0); // EvtChar
    view.setUint16(26, 0, Endian.little); // wReserved1

    final ok = _setCommState(_handle, dcb) != 0;
    calloc.free(dcb);
    if (!ok) return false;

    // COMMTIMEOUTS: return as soon as anything is buffered, otherwise wait.
    final to = calloc<Uint8>(20);
    final toBytes = to.asTypedList(20);
    final toView = ByteData.view(toBytes.buffer, toBytes.offsetInBytes, 20);
    toView.setUint32(0, 0xFFFFFFFF, Endian.little); // ReadIntervalTimeout
    toView.setUint32(4, 0, Endian.little); // ReadTotalTimeoutMultiplier
    toView.setUint32(8, 20, Endian.little); // ReadTotalTimeoutConstant
    toView.setUint32(12, 0, Endian.little); // WriteTotalTimeoutMultiplier
    toView.setUint32(16, 500, Endian.little); // WriteTotalTimeoutConstant
    final okTo = _setCommTimeouts(_handle, to) != 0;
    calloc.free(to);
    if (!okTo) return false;

    _purgeComm(_handle, _purgeTxClear | _purgeRxClear);
    return true;
  }

  void setRts(bool on) =>
      _escapeCommFunction(_handle, on ? _setRts : _clrRts);

  void setDtr(bool on) =>
      _escapeCommFunction(_handle, on ? _setDtr : _clrDtr);

  void purgeInput() => _purgeComm(_handle, _purgeRxClear);

  void writeByte(int value) {
    _buf[0] = value;
    _writeFile(_handle, _buf, 1, _writeCount, nullptr);
  }

  /// Reads up to [max] bytes, waiting at most [timeoutMs] for the first one.
  Uint8List read(int max, int timeoutMs) {
    final out = BytesBuilder(copy: false);
    final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));
    while (out.length < max) {
      if (_readFile(_handle, _buf, max - out.length, _readCount, nullptr) != 0) {
        final n = _readCount.value;
        if (n > 0) {
          out.add(_buf.asTypedList(n).sublist(0, n));
          continue;
        }
      }
      if (DateTime.now().isAfter(deadline)) break;
    }
    return out.toBytes();
  }

  void close() {
    _closeHandle(_handle);
    calloc.free(_readCount);
    calloc.free(_writeCount);
    calloc.free(_buf);
  }
}

/// T=0 transport for a Phoenix/Smartmouse style serial reader.
class PhoenixLink {
  static const int defaultBaud = 19200;

  final _Win32Serial _port;
  int echoErrors = 0;

  PhoenixLink._(this._port);

  /// COM ports that currently exist. Probed by a brief open/close, which does
  /// not touch DTR/RTS, so an attached device is not disturbed.
  static List<String> availablePorts() {
    if (!Platform.isWindows) return const [];

    // Preferred: ask the object manager for the DOS device list. This works
    // even when another process (VMware, a terminal) holds the port open, so
    // the port still shows up and the user gets a clear "cannot open" instead
    // of a silently empty list.
    final named = _Win32Serial.comPorts();
    if (named.isNotEmpty) {
      named.sort((a, b) =>
          int.parse(a.substring(3)).compareTo(int.parse(b.substring(3))));
      return named;
    }

    // Fallback: probe COM1..COM32 by opening each one.
    final found = <String>[];
    for (var i = 1; i <= 32; i++) {
      final name = 'COM$i';
      final probe = _Win32Serial.tryOpen(name);
      if (probe != null) {
        probe.close();
        found.add(name);
      }
    }
    return found;
  }

  static PhoenixLink open(String portName, {int baud = defaultBaud}) {
    final serial = _Win32Serial.tryOpen(portName, baud: baud);
    if (serial == null) {
      throw PhoenixException('cannot open $portName');
    }
    return PhoenixLink._(serial);
  }

  void close() => _port.close();

  Future<void> _delay(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

  /// RTS is wired to RST on a Phoenix reader: assert, release, read the ATR.
  ///
  /// The timings mirror the Python prototype that is known to work on this
  /// hardware (300 ms power settle, 300 ms reset pulse, then read until the
  /// line has been quiet for ~700 ms). A short pulse leaves some eUICCs in a
  /// half-reset state where they still emit an ATR but ignore every APDU.
  Future<Uint8List> reset() async {
    _port.setRts(false);
    _port.setDtr(false);
    await _delay(300);
    _port.purgeInput();
    _port.setRts(true);
    await _delay(300);
    _port.purgeInput();
    _port.setRts(false);

    final atr = <int>[];
    var quiet = 0;
    final deadline = DateTime.now().add(const Duration(milliseconds: 3000));
    while (DateTime.now().isBefore(deadline)) {
      final chunk = _port.read(64, 60);
      if (chunk.isEmpty) {
        quiet++;
        if (atr.isNotEmpty && quiet > 12) break; // ~700 ms of silence
      } else {
        atr.addAll(chunk);
        quiet = 0;
      }
    }
    return Uint8List.fromList(atr);
  }

  /// TX and RX are tied together on the card I/O line, so every transmitted
  /// byte comes back and has to be drained before the card answers.
  Future<void> _txByte(int value) async {
    _port.writeByte(value);
    final echo = _port.read(1, 300);
    if (echo.length != 1 || echo[0] != value) echoErrors++;
  }

  Future<void> _txBytes(Uint8List data) async {
    for (final b in data) {
      await _txByte(b);
    }
  }

  /// First non-NULL byte after a header: either the procedure byte (INS) or
  /// the first byte of the card's answer.
  Future<int> _firstResponseByte() async {
    var b = _port.read(1, 1500);
    while (b.isNotEmpty && b[0] == 0x60) {
      b = _port.read(1, 1500); // NULL: card is still working
    }
    if (b.isEmpty) {
      throw PhoenixException('no response byte (echoErrors=$echoErrors)');
    }
    return b[0];
  }

  /// SW1SW2, skipping the T=0 NULL bytes (0x60) a busy card keeps sending.
  ///
  /// A chunked STORE DATA (AuthenticateServer, LoadBoundProfilePackage) can
  /// take hundreds of milliseconds per block. Treating those NULLs as a
  /// status word aborts a transaction the card is still waiting to finish,
  /// which desynchronises the link until the reader is physically replugged.
  Uint8List _readStatusWord({int timeoutMs = 8000}) {
    int? sw1;
    final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));
    while (DateTime.now().isBefore(deadline)) {
      final b = _port.read(1, 400);
      if (b.isEmpty) continue;
      if (sw1 == null) {
        if (b[0] == 0x60) continue; // NULL: card is still working
        sw1 = b[0];
      } else {
        return Uint8List.fromList([sw1, b[0]]);
      }
    }
    return sw1 == null ? Uint8List(0) : Uint8List.fromList([sw1]);
  }

  /// After a case-4 data field the card either returns Le bytes followed by
  /// SW1SW2, or a bare status word (very common: 61xx / 9000).
  Uint8List _readResponseBody(int le) {
    final first = _port.read(1, 6000);
    if (first.isEmpty) return Uint8List(0);
    final b = first[0];
    if (b == 0x60) return _readStatusWord(); // busy: no data coming
    final hi = b & 0xF0;
    if (b == 0x61 ||
        hi == 0x90 ||
        hi == 0x62 ||
        hi == 0x63 ||
        hi == 0x6A ||
        hi == 0x6B ||
        hi == 0x6C ||
        hi == 0x6D ||
        hi == 0x6E ||
        hi == 0x6F) {
      return Uint8List.fromList([b, ..._port.read(1, 1500)]);
    }
    final rest = _port.read(le - 1, 6000);
    return Uint8List.fromList([b, ...rest, ..._readStatusWord()]);
  }

  /// One T=0 transaction (ISO 7816-3). Handles case 1/2/3/4.
  Future<Uint8List> transceive(Uint8List apdu) async {
    if (apdu.length < 5) {
      throw PhoenixException('APDU shorter than 5 bytes');
    }
    final ins = apdu[1];
    // Le = 0 means 256 bytes (ISO 7816-4) whenever the card acknowledges with
    // its INS byte, which covers GET RESPONSE and every READ BINARY issued
    // with Le 00. It is resolved at the point the ACK is seen, below.
    final p3 = apdu[4];
    final bodyLen = apdu.length - 5;
    // Refuse anything that is not a well-formed case 3/4. A body that is
    // neither Lc nor Lc+1 bytes long would make the card read past Lc, and
    // this reader has no way to power-cycle the card afterwards -- only a
    // physical replug brings it back. Better to fail loudly here.
    if (bodyLen > 0 && bodyLen != p3 && bodyLen != p3 + 1) {
      throw PhoenixException(
        'malformed APDU: Lc=$p3 but $bodyLen data bytes '
        '(refusing to send: it wedges the card until it is replugged)',
      );
    }
    // A case-4 APDU may append a Le byte after Lc data bytes. T=0 carries Le
    // in the header, so that trailing byte must NOT be transmitted: one extra
    // byte makes the card read past Lc, desynchronise, and from then on every
    // answer is garbage (typically a fragment of the ATR).
    final lc = p3 <= bodyLen ? p3 : bodyLen;
    final hasData = lc > 0;
    final le = bodyLen > p3 ? apdu[5 + p3] : 0;

    await _txBytes(Uint8List.sublistView(apdu, 0, 5));

    // Case 3/4: the card acknowledges with the INS byte before taking data.
    if (hasData) {
      final pb = await _firstResponseByte();
      if (pb == (ins ^ 0xFF)) {
        // Complemented INS: the card asks for one data byte at a time, and
        // acknowledges each byte with the complement of INS. Legal T=0, and
        // the only way such a card will accept the body.
        var ack = pb;
        var sent = 0;
        while (sent < lc && ack == (ins ^ 0xFF)) {
          await _txBytes(Uint8List.sublistView(apdu, 5 + sent, 6 + sent));
          sent++;
          ack = await _firstResponseByte();
        }
        if (sent < lc) {
          // The card stopped early; ack is already the first status byte.
          return Uint8List.fromList([ack, ..._port.read(1, 900)]);
        }
        if (le > 0) return _readResponseBody(le);
        return _readStatusWord();
      }
      if (pb == ins) {
        await _txBytes(Uint8List.sublistView(apdu, 5, 5 + lc));
        if (le > 0) return _readResponseBody(le);
        return _readStatusWord();
      }
      return Uint8List.fromList([pb, ..._port.read(1, 900)]);
    }

    // Case 1/2: no input data. The card either sends Le bytes then SW, or SW
    // straight away -- so the first byte is data, not a procedure byte.
    final first = await _firstResponseByte();
    if (first == ins) {
      // The ACK means the data field follows, so Le = 0 is 256 bytes here.
      final body = _port.read(p3 == 0 ? 256 : p3, 5000);
      return Uint8List.fromList([...body, ..._readStatusWord()]);
    }
    if (p3 == 0) {
      return Uint8List.fromList([first, ..._port.read(1, 900)]);
    }
    final body = Uint8List.fromList([first, ..._port.read(p3 - 1, 5000)]);
    return Uint8List.fromList([...body, ..._readStatusWord()]);
  }
}
