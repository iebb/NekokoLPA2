/// Linklan / Linksfield `BLE-eSIM` (LPAd over BLE): protocol and adapter.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:ble/ble.dart';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import '../../main.dart' show navigatorKey;
import '../../utils/error_codes.dart';
import '../euicc_adapter.dart';
import 'ble_adapter.dart';
import 'ble_transport_utils.dart';

class LinklanProtocol {
  LinklanProtocol._();

  // ---------------------------------------------------------- constants --
  /// Nordic UART service; used to identify the service during discovery.
  /// Characteristics are resolved by property, with NUS TX/RX as hints.
  static const String serviceUuid = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  static const String _nusTxHint = '6e400002'; // writable
  static const String _nusRxHint = '6e400003'; // notify/indicate

  static const String deviceNamePrefix = 'ble-esim';

  /// ISD-R applet, selected by the card's own openChannel command.
  static const String isdrAid = 'A0000005591010FFFFFFFF8900000100';

  // Frame command types.
  static const int cmdDevice = 0;
  static const int cmdScard = 2;
  static const int cmdSecurity = 3;

  // SCARD sub-commands.
  static const int scardOpen = 1;
  static const int scardClose = 2;
  static const int scardTransmit = 3;

  /// How long the card needs after a REFRESH before it answers again.
  ///
  /// Five seconds was measured to be too short: the first APDU after it got
  /// 6985. The retry below covers the tail end.
  static const int refreshSettleSeconds = 8;

  /// Maximum bytes per GATT write; a smaller MTU lowers this limit.
  static const int chunkSize = 180;

  /// Smallest frame written, used when the link reports the 23-byte default.
  static const int minChunkSize = 20;

  // STORE DATA splits at this boundary; larger APDUs are ignored.
  static const int storeDataBlockSize = 255;
  static const int storeDataChainedP1 = 0x11;
  static const int storeDataLastBlockP1 = 0x91;

  // Status words the SCARD bridge returns.
  static const int swChannelNotSupported = 0x6881;
  static const int swInstructionNotSupported = 0x6d00;
  static const int swMoreData = 0x61;
  static const int swSuccess = 0x90;
  static const int swSuccessRefresh = 0x91;

  /// True when [sw] signals channel-related rejection.
  static bool isChannelRejection(int sw) =>
      sw == swChannelNotSupported || sw == swInstructionNotSupported;

  // AES-CCM tag length in bits.
  static const int ccmTagBits = 32;

  /// `PSK = HMAC_SHA256(password, "SecurePbChannel")` — r4.a() of the vendor app.
  static Uint8List pskFromPassword(String password) => Uint8List.fromList(
    Hmac(
      sha256,
      utf8.encode(password),
    ).convert(utf8.encode('SecurePbChannel')).bytes,
  );

  /// `mac = HMAC(psk, "SecurePbChannel" || devRandom || cliRandom)`
  static Uint8List sessionMac(
    Uint8List psk,
    Uint8List devRandom,
    Uint8List cliRandom,
  ) => Uint8List.fromList(
    Hmac(sha256, psk).convert(<int>[
      ...utf8.encode('SecurePbChannel'),
      ...devRandom,
      ...cliRandom,
    ]).bytes,
  );

  /// `proof = HMAC(mac[0..16], cliRandom || 0^32)`.
  static Uint8List authProof(Uint8List mac, Uint8List cliRandom) =>
      Uint8List.fromList(
        Hmac(
          sha256,
          mac.sublist(0, 16),
        ).convert(<int>[...cliRandom, ...List<int>.filled(32, 0)]).bytes,
      );

  // -------------------------------------------------------------- protobuf --
  /// Only the wire types this card uses: varint and length-delimited.
  static Uint8List varint(int value) {
    final out = <int>[];
    var v = value;
    do {
      var byte = v & 0x7f;
      v = v >>> 7;
      if (v != 0) byte |= 0x80;
      out.add(byte);
    } while (v != 0);
    return Uint8List.fromList(out);
  }

  static Uint8List pbInt(int field, int value, {bool always = false}) {
    if (value == 0 && !always) return Uint8List(0);
    return concatAll([varint(field << 3), varint(value)]);
  }

  static Uint8List pbBytes(int field, List<int> value) {
    if (value.isEmpty) return Uint8List(0);
    return concatAll([
      varint((field << 3) | 2),
      varint(value.length),
      Uint8List.fromList(value),
    ]);
  }

  static Uint8List concatAll(List<List<int>> parts) {
    final total = parts.fold<int>(0, (sum, part) => sum + part.length);
    final out = Uint8List(total);
    var offset = 0;
    for (final part in parts) {
      out.setRange(offset, offset + part.length, part);
      offset += part.length;
    }
    return out;
  }

  /// Decodes `{field: int | Uint8List}`; a repeated field keeps the last.
  static Map<int, Object> pbDecode(Uint8List data) {
    final out = <int, Object>{};
    var i = 0;
    int readVarint() {
      var shift = 0;
      var result = 0;
      while (i < data.length) {
        final byte = data[i++];
        result |= (byte & 0x7f) << shift;
        if (byte & 0x80 == 0) return result;
        shift += 7;
      }
      throw const FormatException('truncated varint');
    }

    Uint8List take(int length) {
      if (length < 0 || length > data.length - i) {
        throw const FormatException('truncated protobuf field');
      }
      final value = Uint8List.fromList(data.sublist(i, i + length));
      i += length;
      return value;
    }

    while (i < data.length) {
      final key = readVarint();
      final field = key >>> 3;
      final wire = key & 7;
      switch (wire) {
        case 0:
          out[field] = readVarint();
        case 1:
          out[field] = take(8);
        case 2:
          out[field] = take(readVarint());
        case 5:
          out[field] = take(4);
        default:
          throw FormatException('unsupported protobuf wire type $wire');
      }
    }
    return out;
  }

  static Uint8List? pbBytesOf(Map<int, Object> message, int field) {
    final value = message[field];
    return value is Uint8List ? value : null;
  }

  static int pbIntOf(Map<int, Object> message, int field, [int fallback = 0]) {
    final value = message[field];
    return value is int ? value : fallback;
  }

  /// `{1: cmd, 2: payload}`
  static Uint8List frame(int cmd, [List<int> payload = const <int>[]]) =>
      concatAll([pbInt(1, cmd, always: true), pbBytes(2, payload)]);

  /// Frame for the wire: length prefix + message.
  static Uint8List withLengthPrefix(Uint8List message) {
    final len = message.length;
    return Uint8List.fromList([(len >> 8) & 0xff, len & 0xff, ...message]);
  }

  /// Zigzag, as the card expects signed APDU fields to be encoded.
  static int zigzag(int value) => value >= 0 ? value << 1 : ((-value) << 1) - 1;
  static int unzigzag(int value) => (value >> 1) ^ -(value & 1);

  // ----------------------------------------------------------- AES-CCM ------
  /// Session cipher: AES-CCM with a 4-byte tag.
  static Uint8List aesCcmEncrypt(
    Uint8List key,
    Uint8List nonce,
    Uint8List aad,
    Uint8List plaintext,
  ) {
    final ccm = pc.CCMBlockCipher(pc.AESEngine())
      ..init(
        true,
        pc.AEADParameters(pc.KeyParameter(key), ccmTagBits, nonce, aad),
      );
    return ccm.process(plaintext);
  }

  static Uint8List aesCcmDecrypt(
    Uint8List key,
    Uint8List nonce,
    Uint8List aad,
    Uint8List ciphertext,
  ) {
    final ccm = pc.CCMBlockCipher(pc.AESEngine())
      ..init(
        false,
        pc.AEADParameters(pc.KeyParameter(key), ccmTagBits, nonce, aad),
      );
    return ccm.process(ciphertext);
  }

  /// Adds [counter] to the big-endian nonce.
  static Uint8List nonceFor(Uint8List base, int counter) {
    // Carry across the whole nonce, as the stock session code does.
    final nonce = Uint8List.fromList(base);
    var carry = counter;
    for (var i = nonce.length - 1; i >= 0 && carry > 0; i--) {
      final total = nonce[i] + (carry & 0xff);
      nonce[i] = total & 0xff;
      carry = (carry >> 8) + (total >> 8);
    }
    return nonce;
  }

  /// One field-2 wrapper; another makes the card re-challenge.
  static Uint8List authFrame(Uint8List cliRandom, Uint8List proof) => frame(
    cmdSecurity,
    pbBytes(
      3,
      pbBytes(2, concatAll([pbBytes(1, cliRandom), pbBytes(2, proof)])),
    ),
  );

  /// UPDATE proof `HMAC(mac[0..16], nonce ‖ aad ‖ 0³²)`; a wrong password lands here.
  static bool verifyUpdateProof(
    Uint8List mac,
    Uint8List nonce,
    Uint8List aad,
    Uint8List? configAuth,
  ) {
    if (configAuth == null) return true; // The proof field is optional.
    final expected = authProof(mac, concatAll([nonce, aad]));
    return bytesToHex(expected) == bytesToHex(configAuth);
  }

  /// STORE DATA blocks with the block index in P2 and `0x91` on the last one.
  static List<({int p1, int p2, Uint8List chunk})> storeDataBlocks(
    Uint8List data, {
    int blockSize = storeDataBlockSize,
  }) {
    final totalBlocks = (data.length + blockSize - 1) ~/ blockSize;
    return <({int p1, int p2, Uint8List chunk})>[
      for (var blockIndex = 0; blockIndex < totalBlocks; blockIndex++)
        (
          p1: blockIndex == totalBlocks - 1
              ? storeDataLastBlockP1
              : storeDataChainedP1,
          p2: blockIndex & 0xff,
          chunk: data.sublist(
            blockIndex * blockSize,
            min(blockIndex * blockSize + blockSize, data.length),
          ),
        ),
    ];
  }

  // ------------------------------------------------------------ commands ----
  static Uint8List getDeviceInfo() =>
      frame(cmdDevice, pbInt(1, 1, always: true));

  /// `SmartCardReq` payload: the AID as ASCII hex text, not raw bytes.
  static Uint8List openChannel(String aidHex, {int channel = 0}) => concatAll([
    pbInt(1, scardOpen, always: true),
    pbBytes(
      2,
      concatAll([
        pbBytes(1, ascii.encode(aidHex.replaceAll(' ', '').toUpperCase())),
        pbInt(2, channel),
      ]),
    ),
  ]);

  static Uint8List closeChannel(int channel) =>
      concatAll([pbInt(1, scardClose, always: true), pbInt(3, channel)]);

  /// `TransmitApduRequest{1: channel, 2..5: cla/ins/p1/p2, 6: length, 7: data hex}`
  static Uint8List transmitApdu({
    required int channel,
    required int cla,
    required int ins,
    required int p1,
    required int p2,
    required Uint8List data,
    int? p3,
  }) => concatAll([
    pbInt(1, scardTransmit, always: true),
    pbBytes(
      4,
      concatAll([
        pbInt(1, zigzag(channel)),
        pbInt(2, zigzag(cla)),
        pbInt(3, zigzag(ins)),
        pbInt(4, zigzag(p1)),
        pbInt(5, zigzag(p2)),
        pbInt(6, zigzag(p3 ?? data.length)),
        pbBytes(7, ascii.encode(bytesToHex(data))),
      ]),
    ),
  ]);

  static Uint8List hexToBytes(String hex) {
    final clean = hex.replaceAll(RegExp(r'\s+'), '');
    final out = Uint8List(clean.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  static String bytesToHex(List<int> bytes) => bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join()
      .toUpperCase();
}

/// Adapter for cards advertising as `BLE-eSIM-XXXXXXXX`.
class LinklanAdapter extends BaseAdapter implements BleAdapter {
  LinklanAdapter() : super(_log);

  static final Logger _log = Logger('LinklanAdapter');

  /// Stored per card, keyed by the advertised name.
  static const String storedPasswordKeyPrefix = 'linklan_password_';

  final StreamController<EuiccPortState> _stateController =
      StreamController<EuiccPortState>.broadcast();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeChar;
  BluetoothCharacteristic? _notifyChar;
  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<BluetoothConnectionState>? _connSub;

  String? _deviceId;
  String? _deviceName;
  bool _transportReady = false;
  bool _disconnectRequested = false;
  bool _authenticated = false;

  final LinklanFrameAssembler _rx = LinklanFrameAssembler();
  int _linkGeneration = 0;

  _LinklanOperation? _operation;

  @override
  Future<T> runExclusive<T>(Future<T> Function() action) =>
      super.runExclusive(() async {
        final current = _operation;
        if (current != null) {
          current.check();
          return await action();
        }
        final operation = _operation = _LinklanOperation();
        try {
          final result = await action();
          operation.check();
          return result;
        } finally {
          _operation = null;
        }
      });

  /// Whether the request that triggered the current session has been replayed.
  bool _requestReplayed = false;

  /// Set when a frame was only partly written: the stream is desynchronised and
  /// must not be written to again until a new link exists.
  bool _linkBroken = false;
  Completer<Uint8List>? _pendingResponse;
  Timer? _pendingTimer;

  Uint8List? _psk;

  /// The password this link authenticated with, for the settings screen.
  String? _password;
  String? get password => _password;

  /// Whether the PSK in use came from the stored password, not the prompt.
  bool _pskFromStorage = false;

  /// Whether the card proved the session key in its handshake reply. It may
  /// leave the proof out, and then a wrong password only shows when the first
  /// reply fails to decrypt.
  bool _sessionProven = true;

  /// Whether a reply has decrypted under the current session key.
  bool _sessionDecrypted = false;

  Uint8List? _key;
  Uint8List? _nonce;
  Uint8List? _aad;
  int _counter = 0;
  int _channel = 0;
  int? _nextStoreBlock;
  List<int> _channelCandidates = const <int>[];

  /// Channel that served an APDU last, so the probe runs once per link.
  int _preferredChannel = 0;
  _LinklanChannel? _linklanChannel;

  /// Set while the card applies a REFRESH; APDUs wait instead of failing.
  DateTime? _refreshingUntil;

  /// When the last reset was sent, so a card that answers "profile state change
  /// ongoing" while it comes back can be retried instead of failing the caller.
  DateTime? _lastResetAt;

  /// Chunk size for a reported MTU, capped at [LinklanProtocol.chunkSize].
  int _chunkForMtu(int mtu) {
    final usable = mtu - 3;
    if (usable <= LinklanProtocol.minChunkSize) {
      return LinklanProtocol.minChunkSize;
    }
    return usable < LinklanProtocol.chunkSize
        ? usable
        : LinklanProtocol.chunkSize;
  }

  Future<void> _awaitRefreshWindow() async {
    final until = _refreshingUntil;
    if (until == null) return;
    final wait = until.difference(DateTime.now());
    if (wait.isNegative || wait.inMilliseconds == 0) {
      _refreshingUntil = null;
      return;
    }
    _log.fine('Linklan: waiting ${wait.inMilliseconds} ms for the card reset');
    await _operation!.delay(wait);
    _refreshingUntil = null;
  }

  int _chunk = LinklanProtocol.chunkSize;

  @override
  Stream<EuiccPortState> get stateStream => _stateController.stream;

  @override
  bool get requiresRefresh => false;

  /// No raw-APDU access: the bridge only expresses one P3 (either Lc or Le), so a
  /// case-4 command cannot be sent correctly, and the channel it would use is the
  /// ISD-R one. eUICC operations go through [Channel] instead.
  @override
  bool get supportsRawApdu => false;

  @override
  String? get lastAtr => null;

  @override
  NotificationStrategy get notificationStrategy => NotificationStrategy.twoStep;

  @override
  Future<List<Reader>> listReaders({bool force = false}) async =>
      connectedReader == null ? [] : [connectedReader!];

  static bool isDeviceName(String name) =>
      name.toLowerCase().contains(LinklanProtocol.deviceNamePrefix);

  static String storedPasswordKey(String deviceName) =>
      '$storedPasswordKeyPrefix${_stableName(deviceName)}';

  /// Card name without the vendor's `|`-suffixed extras.
  static String _stableName(String deviceName) =>
      deviceName.split('|').first.trim();

  static Future<List<LinklanStoredPassword>> loadStoredPasswords() async {
    final prefs = await SharedPreferences.getInstance();
    final records = <LinklanStoredPassword>[];
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(storedPasswordKeyPrefix)) continue;

      final deviceName = key.substring(storedPasswordKeyPrefix.length).trim();
      final password = prefs.getString(key);
      if (deviceName.isEmpty || password == null || password.isEmpty) continue;

      records.add(
        LinklanStoredPassword(deviceName: deviceName, password: password),
      );
    }
    records.sort(
      (a, b) =>
          a.deviceName.toLowerCase().compareTo(b.deviceName.toLowerCase()),
    );
    return records;
  }

  static Future<void> savePasswordForDevice({
    required String previousDeviceName,
    required String deviceName,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final previousKey = storedPasswordKey(previousDeviceName);
    final newKey = storedPasswordKey(deviceName);
    if (previousDeviceName.trim().isNotEmpty && previousKey != newKey) {
      await prefs.remove(previousKey);
    }
    await prefs.setString(newKey, password.trim());
  }

  // ------------------------------------------------------------- connect ---
  @protected
  Future<BluetoothDevice> openBleDevice(String deviceId) async {
    if (await _operation!.waitFor(Ble.adapterState.first) !=
        BluetoothAdapterState.on) {
      reportConnectStep(ReaderConnectStep.waitingForBluetooth);
      await _operation!.waitFor(
        Ble.adapterState
            .where((state) => state == BluetoothAdapterState.on)
            .first
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () =>
                  throw AppException(AppErrorCode.ERROR_BLUETOOTH_DISABLED),
            ),
      );
    }
    _operation!.check();
    final device = BluetoothDevice.fromId(deviceId);
    await connectBleDevice(
      device,
      _log,
      preferredMtu: 512,
      progress: connectProgress,
    );
    return device;
  }

  @override
  Future<void> connect(Reader reader) async {
    final parts = reader.id.split('|');
    final deviceId = parts.isNotEmpty ? parts.last.trim() : reader.id.trim();
    final deviceName = reader.name.trim();

    await runExclusive(() async {
      if (_deviceId == deviceId && _transportReady) {
        updateConnectedReader(reader);
        return;
      }
      await _tearDown(emitClosed: false);
      _operation!.check();
      updateConnectedReader(reader);
      _deviceId = deviceId;
      _deviceName = deviceName;
      _disconnectRequested = false;
      _linkBroken = false;
      try {
        _device = await openBleDevice(deviceId);
        _operation!.check();
        final generation = _linkGeneration;
        _connSub = _device!.connectionState.listen((state) {
          if (generation == _linkGeneration &&
              !_linkBroken &&
              state == BluetoothConnectionState.disconnected) {
            _loseLink(AppException(AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED));
          }
        });
        _chunk = _chunkForMtu(_device!.mtuNow);
        _log.info('Linklan chunk size $_chunk (mtu ${_device!.mtuNow})');
        reportConnectStep(ReaderConnectStep.discoveringServices);
        final services = await _device!.discoverServices();
        _operation!.check();
        BluetoothService? nus;
        for (final service in services) {
          if (service.uuid.toString().toLowerCase() ==
              LinklanProtocol.serviceUuid) {
            nus = service;
            break;
          }
        }
        if (nus == null) {
          throw AppException(
            AppErrorCode.ERROR_BLUETOOTH_SERVICE_NOT_FOUND,
            message: 'Linklan NUS service not found',
          );
        }

        // Discover TX/RX by property, preferring the NUS UUIDs as hints.
        BluetoothCharacteristic? writerHinted;
        BluetoothCharacteristic? notifierHinted;
        BluetoothCharacteristic? writerFallback;
        BluetoothCharacteristic? notifierFallback;
        for (final characteristic in nus.characteristics) {
          final uuid = characteristic.uuid.toString().toLowerCase();
          final canWrite = characteristic.properties.write;
          final canNotify =
              characteristic.properties.notify ||
              characteristic.properties.indicate;
          if (uuid.contains(LinklanProtocol._nusTxHint) && canWrite) {
            writerHinted = characteristic;
          }
          if (uuid.contains(LinklanProtocol._nusRxHint) && canNotify) {
            notifierHinted = characteristic;
          }
          if (canWrite) writerFallback ??= characteristic;
          if (canNotify) notifierFallback ??= characteristic;
        }
        _writeChar = writerHinted ?? writerFallback;
        _notifyChar = notifierHinted ?? notifierFallback;
        if (_writeChar != null) {
          _log.info('Linklan TX characteristic: ${_writeChar!.uuid}');
        }
        if (_notifyChar != null) {
          _log.info('Linklan RX characteristic: ${_notifyChar!.uuid}');
        }
        if (_writeChar == null) {
          throw AppException(
            AppErrorCode.ERROR_BLUETOOTH_CHARACTERISTIC_NOT_FOUND,
            message: 'Linklan: no characteristic supports writes with response',
          );
        }
        if (_notifyChar == null) {
          throw AppException(
            AppErrorCode.ERROR_BLUETOOTH_CHARACTERISTIC_NOT_FOUND,
            message: 'Linklan notify characteristic not found',
          );
        }

        _notifySub = _notifyChar!.onValueReceived.listen((bytes) {
          if (generation == _linkGeneration && !_linkBroken) {
            _handleNotification(bytes);
          }
        });
        reportConnectStep(ReaderConnectStep.enablingNotifications);
        await _notifyChar!.setNotifyValue(true);

        reportConnectStep(ReaderConnectStep.authenticating);
        await _authenticateWithPasswordPrompt();
        await _replayPendingRequest();
        _operation!.check();
      } catch (error) {
        await _tearDown(emitClosed: false);
        rethrow;
      }
      _transportReady = true;
      _stateController.add(EuiccPortState.open);
    });
  }

  /// Replays the request that triggered the handshake; SCARD answers error 5 without it.
  Future<void> _replayPendingRequest({
    int reauthBudget = 6,
    Duration? timeout,
  }) async {
    if (!_authenticated) {
      throw AppException(
        AppErrorCode.ERROR_REMOTE_AUTH_FAILED,
        message: 'Linklan: session lost before the request could be replayed',
      );
    }
    if (_requestReplayed) return;
    await _request(
      LinklanProtocol.cmdDevice,
      LinklanProtocol.pbInt(1, 1, always: true),
      reauthBudget,
      timeout,
    );
    _requestReplayed = true;
    _log.info('Linklan: replayed the pending device request');
  }

  /// The password stored for this card, if any.
  ///
  /// The factory password is the last six digits of the card's EID, and the EID
  /// only becomes readable once the session is up, so there is nothing to derive
  /// here: ask once and keep it. No way to change the password was found either.
  Future<String?> _passwordFor(String deviceName) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(storedPasswordKey(deviceName))?.trim();
    return (stored == null || stored.isEmpty) ? null : stored;
  }

  /// Handshakes with the stored password, asking when there is none or the card
  /// rejects it.
  Future<void> _authenticateWithPasswordPrompt({
    List<int>? challengeProto,
  }) async {
    _checkLink();
    final deviceName = _deviceName!;
    final stored = _password ?? await _passwordFor(deviceName);
    _checkLink();
    if (stored != null) {
      _psk = LinklanProtocol.pskFromPassword(stored);
      _pskFromStorage = true;
      try {
        await _authenticate(challengeProto: challengeProto);
        _checkLink();
        _password = stored;
        return;
      } on AppException catch (e) {
        final rejected =
            e.code == AppErrorCode.ERROR_REMOTE_WRONG_PASSWORD ||
            e.code == AppErrorCode.ERROR_REMOTE_AUTH_FAILED;
        if (!rejected) rethrow;
        _log.warning(
          'Linklan authentication failed, prompting for a password.',
        );
        _psk = null;
        _password = null;
      }
    }

    final typed = await _promptForPassword();
    _checkLink();
    if (typed == null || typed.trim().isEmpty) {
      throw AppException(
        AppErrorCode.ERROR_REMOTE_WRONG_PASSWORD,
        message: 'Linklan: authentication cancelled by the user',
      );
    }

    final trimmed = typed.trim();
    _psk = LinklanProtocol.pskFromPassword(trimmed);
    _pskFromStorage = false;
    // A challenge that already failed a proof cannot be reused, so ask for a
    // new one and replay it.
    await _authenticate();
    await _replayPendingRequest(reauthBudget: 0);
    // Only a password the card accepted is worth remembering; this card issues a
    // fresh challenge per attempt, so proving first costs nothing and a typo is
    // never stored.
    await savePasswordForDevice(
      previousDeviceName: deviceName,
      deviceName: deviceName,
      password: trimmed,
    );
    _checkLink();
    _password = trimmed;
  }

  // ----------------------------------------------------------- transport ---
  void _handleNotification(List<int> value) {
    for (final message in _rx.add(value)) {
      final completer = _pendingResponse;
      _pendingResponse = null;
      _pendingTimer?.cancel();
      _log.fine('Linklan RX ${message.length} B');
      completer?.complete(message);
    }
  }

  void _checkLink() {
    _operation!.check();
    if (_writeChar == null || _device == null || _linkBroken) {
      throw AppException(
        AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED,
        message: 'Linklan is not connected',
      );
    }
  }

  Future<Uint8List> _send(Uint8List message, {Duration? timeout}) async {
    _checkLink();
    final frame = LinklanProtocol.withLengthPrefix(message);
    _log.fine('Linklan TX ${message.length} B');
    _rx.reset();
    final completer = Completer<Uint8List>();
    // The timer or an interrupt can fail the future before this method returns
    // it, so give it a listener now; the caller still receives the error.
    completer.future.ignore();
    _pendingResponse = completer;
    _pendingTimer?.cancel();
    _pendingTimer = Timer(timeout ?? const Duration(seconds: 20), () {
      if (!completer.isCompleted) {
        _pendingResponse = null;
        final error = AppException(
          AppErrorCode.ERROR_BLUETOOTH_TIMEOUT,
          message: 'Linklan did not answer in time',
        );
        completer.completeError(error);
        // Even a read-only probe can reply late. Frames have no request ID.
        _breakLink(error);
      }
    });

    try {
      for (var offset = 0; offset < frame.length;) {
        _checkLink();
        if (completer.isCompleted) {
          final error = AppException(
            AppErrorCode.ERROR_TRANSACTION_FAILED,
            message: 'Linklan replied before the full frame was written',
          );
          _breakLink(error);
          throw error;
        }
        // The reported MTU arrives asynchronously (iOS polls for it), so read it
        // per write instead of trusting the value sampled at connect time. The
        // link can also disappear between chunks.
        final usable = _chunkForMtu(_device!.mtuNow);
        if (usable != _chunk) {
          _chunk = usable;
          _log.info('Linklan chunk size $_chunk');
        }
        final size = min(_chunk, frame.length - offset);
        final slice = Uint8List.sublistView(frame, offset, offset + size);
        await _operation!.waitFor(
          _writeChar!.write(slice, withoutResponse: false),
        );
        offset += size;
      }
    } catch (error) {
      // The frame may be half-written, so never resend it on this stream.
      _breakLink(
        AppException(
          AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED,
          message: 'Linklan write interrupted',
        ),
      );
      rethrow;
    }
    final response = await completer.future;
    _checkLink();
    return response;
  }

  /// Bare ciphertext, a security protocol, or either nested one level deeper.
  ({String kind, Uint8List value, int code}) _classify(Uint8List response) {
    final Map<int, Object> message;
    try {
      message = LinklanProtocol.pbDecode(response);
    } catch (_) {
      return (kind: 'plain', value: response, code: 0);
    }
    final enc = LinklanProtocol.pbBytesOf(message, 2);
    final encSec = LinklanProtocol.pbBytesOf(message, 4);
    final sec = LinklanProtocol.pbBytesOf(message, 3);
    final dsec = LinklanProtocol.pbBytesOf(message, 5);
    if (enc != null && enc.isNotEmpty) {
      return (kind: 'enc', value: enc, code: 0);
    }
    // Some replies carry the ciphertext in field 4 instead of 2; the cause is
    // not known, so both are accepted.
    if (encSec != null && encSec.isNotEmpty) {
      return (kind: 'enc', value: encSec, code: 0);
    }
    if (sec != null && sec.isNotEmpty) {
      return (kind: 'protocol', value: sec, code: 0);
    }
    if (dsec != null && dsec.isNotEmpty) {
      return (kind: 'protocol', value: dsec, code: 0);
    }
    final err = message[5];
    if (err is int) return (kind: 'error', value: Uint8List(0), code: err);
    return (kind: 'plain', value: response, code: 0);
  }

  // ------------------------------------------------------------ security ---
  Future<void> _authenticate({List<int>? challengeProto}) async {
    // A new session always starts with a fresh pending request.
    _requestReplayed = false;
    final ({String kind, Uint8List value, int code}) classified;
    if (challengeProto != null) {
      classified = (
        kind: 'protocol',
        value: Uint8List.fromList(challengeProto),
        code: 0,
      );
    } else {
      final challenge = await _send(LinklanProtocol.getDeviceInfo());
      classified = _classify(challenge);
    }
    if (classified.kind != 'protocol') {
      throw AppException(
        AppErrorCode.ERROR_REMOTE_AUTH_FAILED,
        message: 'Linklan: no authentication challenge (${classified.kind})',
      );
    }
    // SecurityProtocol{ 2: SecurityAuth{ 1: devRandom } }
    final protocol = _decodeReply(classified.value);
    final auth = LinklanProtocol.pbBytesOf(protocol, 2);
    final devRandom = auth == null
        ? null
        : LinklanProtocol.pbBytesOf(_decodeReply(auth), 1);
    if (devRandom == null || devRandom.length != 16) {
      throw AppException(
        AppErrorCode.ERROR_REMOTE_AUTH_FAILED,
        message: 'Linklan: challenge carries no random',
      );
    }

    final psk = _psk;
    if (psk == null) {
      throw AppException(
        AppErrorCode.ERROR_REMOTE_AUTH_FAILED,
        message: 'Linklan: no PSK',
      );
    }
    final cliRandom = Uint8List.fromList(
      List<int>.generate(16, (_) => Random.secure().nextInt(256)),
    );
    final mac = LinklanProtocol.sessionMac(psk, devRandom, cliRandom);
    final proof = LinklanProtocol.authProof(mac, cliRandom);

    final frame = LinklanProtocol.authFrame(cliRandom, proof);
    final response = await _send(frame);
    final result = _classify(response);
    // The reply carries the card's config, and the request that produces it
    // carries the proof; neither belongs in a log that error reports ship.
    _log.info('Linklan handshake reply: ${result.kind} (${response.length} B)');
    if (result.kind != 'protocol') {
      throw AppException(
        AppErrorCode.ERROR_REMOTE_AUTH_FAILED,
        message:
            'Linklan: the card refused the handshake (${result.kind}'
            '${result.code != 0 ? ' ${result.code}' : ''})',
      );
    }
    final protocolMessage = _decodeReply(result.value);
    final config = LinklanProtocol.pbBytesOf(protocolMessage, 3);
    if (config == null) {
      throw AppException(
        AppErrorCode.ERROR_REMOTE_AUTH_FAILED,
        message: 'Linklan: handshake answered without a config',
      );
    }
    final fields = _decodeReply(config);
    final nonce = LinklanProtocol.pbBytesOf(fields, 1);
    final aad = LinklanProtocol.pbBytesOf(fields, 2);
    if (nonce == null || nonce.length != 12 || aad == null) {
      throw AppException(
        AppErrorCode.ERROR_REMOTE_AUTH_FAILED,
        message: 'Linklan: config without a 12-byte nonce/aad',
      );
    }
    // A wrong password surfaces here, unless the card left the proof out.
    final updateProof = LinklanProtocol.pbBytesOf(fields, 3);
    if (!LinklanProtocol.verifyUpdateProof(mac, nonce, aad, updateProof)) {
      throw AppException(
        AppErrorCode.ERROR_REMOTE_WRONG_PASSWORD,
        message: 'Linklan: the card rejected our proof (wrong password)',
      );
    }
    _checkLink();
    _key = mac.sublist(16, 32);
    _nonce = nonce;
    _aad = aad;
    _counter = 0;
    _sessionProven = updateProof != null;
    _sessionDecrypted = false;
    _authenticated = true;
    _log.info('Linklan secure channel established');
    return;
  }

  Future<Uint8List> _request(
    int cmd, [
    List<int> payload = const <int>[],
    int reauthBudget = 6,
    Duration? timeout,
  ]) async {
    _checkLink();
    final inner = LinklanProtocol.frame(cmd, payload);
    if (!_authenticated) {
      // Never put an APDU on the wire in clear: the card does not need it to
      // start a session (the handshake runs on its own device request), and a
      // STORE DATA payload would expose profile data.
      await _authenticateWithPasswordPrompt();
      await _replayPendingRequest(reauthBudget: 0, timeout: timeout);
      return _request(cmd, payload, reauthBudget, timeout);
    }

    final key = _key!;
    final baseNonce = _nonce!;
    final aad = _aad!;
    _counter += 1;
    final nonce = LinklanProtocol.nonceFor(baseNonce, _counter);
    final ciphertext = LinklanProtocol.aesCcmEncrypt(key, nonce, aad, inner);
    final wrapper = LinklanProtocol.frame(
      LinklanProtocol.cmdSecurity,
      LinklanProtocol.concatAll([
        LinklanProtocol.pbInt(1, _counter, always: true),
        LinklanProtocol.pbBytes(2, ciphertext),
      ]),
    );
    final response = await _send(wrapper, timeout: timeout);
    final result = _classify(response);
    _log.fine('Linklan cmd=$cmd -> ${result.kind} (${response.length} B)');
    if (result.kind == 'enc') {
      final Uint8List plain;
      try {
        plain = LinklanProtocol.aesCcmDecrypt(key, nonce, aad, result.value);
      } catch (_) {
        // With no proof in the handshake, the first reply failing to decrypt is
        // how a wrong password shows. The link is broken by then, so forget a
        // stored password and let the next connect ask for it.
        final wrongPassword = !_sessionProven && !_sessionDecrypted;
        final deviceName = _deviceName;
        if (wrongPassword && _pskFromStorage && deviceName != null) {
          _log.warning('Linklan: forgetting the stored password it rejected');
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(storedPasswordKey(deviceName));
        }
        final failure = wrongPassword
            ? AppException(
                AppErrorCode.ERROR_REMOTE_WRONG_PASSWORD,
                message:
                    'Linklan: the card did not accept the password; '
                    'connect again to enter it',
              )
            : AppException(
                AppErrorCode.ERROR_REMOTE_AUTH_FAILED,
                message: 'Linklan: invalid session reply',
              );
        _breakLink(failure);
        throw failure;
      }
      _sessionDecrypted = true;
      return plain;
    }
    if (result.kind == 'error' && result.code == 5 && reauthBudget > 0) {
      // Back off before asking the card for a fresh session.
      await _operation!.delay(const Duration(milliseconds: 1500));
      _log.info(
        'Linklan: card rejected the frame (error 5 at counter '
        '$_counter), handshaking again',
      );
      _authenticated = false;
      await _authenticateWithPasswordPrompt();
      // That handshake asked the card for a new challenge, which is now the
      // pending request; replay it or the card answers error 5 again.
      // The replay must not start a handshake of its own; the allowance below
      // already pays for this one.
      await _replayPendingRequest(reauthBudget: 0, timeout: timeout);
      return _request(cmd, payload, reauthBudget - 1, timeout);
    }
    if (result.kind == 'protocol' && reauthBudget > 0) {
      _log.info('Linklan: card asked for a new session, re-handshaking');
      _authenticated = false;
      _password = null;
      await _authenticateWithPasswordPrompt(challengeProto: result.value);
      return _request(cmd, payload, reauthBudget - 1, timeout);
    }
    if (result.kind == 'error' && result.code == 5) {
      throw AppException(
        AppErrorCode.ERROR_TRANSACTION_FAILED,
        message:
            'Linklan rejected every session counter (error 5). The card is '
            'wedged — power-cycle it (a plain-text reset is not honoured).',
      );
    }
    throw AppException(
      AppErrorCode.ERROR_TRANSACTION_FAILED,
      message:
          'Linklan: ${result.kind} response'
          '${result.code != 0 ? ' (code ${result.code})' : ''}',
    );
  }

  // --------------------------------------------------------------- SCARD ---
  /// Opens the ISD-R channel and returns the number the card allocated.
  Future<({int result, int channel})> _openScardChannel(String aidHex) async {
    final response = await _request(
      LinklanProtocol.cmdScard,
      LinklanProtocol.openChannel(aidHex),
    );
    final parsed = LinklanAdapter.parseOpenChannelRsp(response);
    final result = parsed.result;
    final channel = parsed.channel;
    if (parsed.candidates.isNotEmpty) _channelCandidates = parsed.candidates;
    if (result != 0) {
      // The bridge refused, typically because leaked channels filled its table.
      // Hand the result back so the caller can reclaim and retry.
      return (result: result, channel: 0);
    }
    if (channel <= 0) {
      throw AppException(
        AppErrorCode.ERROR_CHANNEL_OPEN_FAILED,
        message: 'Linklan: openChannel reported no usable channel',
      );
    }
    _log.info('Linklan openChannel: result=$result channel=$channel');
    return (result: result, channel: channel);
  }

  /// Decodes a reply from the card, reporting a malformed one as a failed
  /// transaction rather than a raw [FormatException].
  static Map<int, Object> _decodeReply(Uint8List data) {
    try {
      return LinklanProtocol.pbDecode(data);
    } on FormatException catch (e) {
      throw AppException(
        AppErrorCode.ERROR_TRANSACTION_FAILED,
        message: 'Linklan: malformed reply (${e.message})',
        originalError: e,
      );
    }
  }

  /// `SmartCardRsp{1: cmd, 2: result, 3: OpenChannelRsp{1: packed channels}}`.
  static ({int result, int channel, List<int> candidates}) parseOpenChannelRsp(
    Uint8List message,
  ) {
    final decoded = _decodeReply(message);
    final payload = LinklanProtocol.pbBytesOf(decoded, 3);
    final packed = payload == null
        ? null
        : LinklanProtocol.pbBytesOf(_decodeReply(payload), 1);
    final candidates = LinklanAdapter.channelCandidatesFromOpenChannelRsp(
      packed,
    );
    return (
      result: LinklanProtocol.pbIntOf(decoded, 2),
      channel: candidates.isEmpty ? 0 : candidates.first,
      candidates: candidates,
    );
  }

  /// Whether the card actually serves APDUs on `channel`.
  Future<bool> _channelServes(int channel) async {
    final probeResponse = await _transmitOnce(
      channel,
      0x80, // ES10 CLA
      0xe2,
      0x91,
      0x00,
      LinklanProtocol.hexToBytes('BF3E035C015A'),
      timeout: const Duration(seconds: 5),
    );
    return classifyContinuation(probeResponse.sw).kind != 'refused';
  }

  /// Channel from `OpenChannelRsp.data`, keeping the raw reading as a fallback.
  static List<int> channelCandidatesFromOpenChannelRsp(Uint8List? packed) {
    if (packed == null || packed.isEmpty) return const <int>[];
    var raw = 0;
    var shift = 0;
    for (final byte in packed) {
      raw |= (byte & 0x7f) << shift;
      if (byte & 0x80 == 0) break;
      shift += 7;
    }
    final zigzag = (raw >> 1) ^ -(raw & 1);
    return <int>[if (zigzag > 0) zigzag, if (raw > 0 && raw != zigzag) raw];
  }

  /// What a continuation status word asks the caller to do.
  ///
  /// `61 xx` = more data follows, `6C xx` = re-issue with that Le, `6D/6E/68 xx`
  /// = the channel or command is unusable, anything else is the final status.
  @visibleForTesting
  static ({String kind, int length}) classifyContinuation(int sw) {
    final sw1 = (sw >> 8) & 0xff;
    final sw2 = sw & 0xff;
    if (sw1 == 0x61) return (kind: 'more', length: sw2);
    if (sw1 == 0x6c) return (kind: 'correctedLe', length: sw2);
    if (sw1 == 0x6d || sw1 == 0x6e || sw1 == 0x68) {
      return (kind: 'refused', length: 0);
    }
    return (kind: 'final', length: 0);
  }

  static int channelFromOpenChannelRsp(Uint8List? packed) {
    final candidates = channelCandidatesFromOpenChannelRsp(packed);
    return candidates.isEmpty ? 0 : candidates.first;
  }

  /// Opens the ISD-R channel, reclaiming leaked ones if the card refuses.
  ///
  /// Try reclaiming channel numbers only on the bridge's capacity error.
  Future<({int result, int channel})> _openChannelWithRecovery(
    String aidHex,
  ) async {
    var opened = await _openScardChannel(aidHex);
    if (opened.result == 0) return opened;
    if (opened.result != 1) {
      // 1 means the card's channel table is full. Any other refusal must not be
      // answered by closing channel numbers this adapter does not own.
      return opened;
    }
    _log.info(
      'Linklan: openChannel result=${opened.result}, reclaiming channels',
    );
    for (var ch = 1; ch <= 16; ch++) {
      try {
        await _request(
          LinklanProtocol.cmdScard,
          LinklanProtocol.closeChannel(ch),
        );
      } catch (_) {
        _checkLink();
      }
    }
    opened = await _openScardChannel(aidHex);
    return opened;
  }

  /// Picks the channel the card serves, preferring the one already in use.
  ///
  /// An explicit rejection can be probed on another channel; a missing reply
  /// ends the link because its notifications cannot be matched to a request.
  Future<int> _pickChannel(int announced) async {
    _log.info(
      'Linklan: pickChannel(announced=$announced, preferred=$_preferredChannel)',
    );
    if (_preferredChannel != 0) return _preferredChannel;
    final candidates = _channelCandidates.isEmpty
        ? <int>{announced, 1}
        : _channelCandidates.toSet();
    for (final candidate in candidates) {
      if (await _channelServes(candidate)) {
        _log.info(
          'Linklan: channel $candidate serves APDUs '
          '(announced $announced)',
        );
        _preferredChannel = candidate;
        return candidate;
      }
    }
    throw AppException(
      AppErrorCode.ERROR_CHANNEL_OPEN_FAILED,
      message: 'Linklan: no channel answered the probe',
    );
  }

  Future<void> _ensureChannel() async {
    _log.info(
      'Linklan: ensureChannel (channel=$_channel preferred=$_preferredChannel)',
    );
    _checkLink();
    if (_channel != 0) return;

    var opened = await _openChannelWithRecovery(LinklanProtocol.isdrAid);
    var result = opened.result;
    if (result == 1) {
      // 1 means the table is full; a leaked channel from an earlier session is
      // the only thing the sweep can fix. Other refusals are propagated.
      _log.info('Linklan openChannel result=$result, releasing stale channels');
      for (var channel = 1; channel <= 5; channel++) {
        try {
          await _request(
            LinklanProtocol.cmdScard,
            LinklanProtocol.closeChannel(channel),
          );
        } catch (_) {
          _checkLink();
        }
      }
      opened = await _openScardChannel(LinklanProtocol.isdrAid);
      result = opened.result;
    }
    if (result != 0) {
      throw AppException(
        AppErrorCode.ERROR_CHANNEL_OPEN_FAILED,
        message: 'Linklan: no free logical channel (result $result)',
      );
    }
    // Keep the allocation until the probe succeeds so an explicit refusal
    // doesn't leak it. A transport failure already invalidates the link.
    _channel = opened.channel;
    try {
      final picked = await _pickChannel(opened.channel);
      _checkLink();
      _channel = picked;
    } catch (_) {
      await _releaseChannel();
      rethrow;
    }
  }

  Future<void>? _disconnecting;

  void _breakLink(AppException error) {
    if (_linkBroken) return;
    _loseLink(error);
    _disconnecting = _device?.disconnect().catchError((Object _) {});
  }

  void _loseLink(AppException error) {
    _linkBroken = true;
    _transportReady = false;
    _operation?.cancel(error);
    _invalidateSession(error);
    if (!_disconnectRequested) _stateController.add(EuiccPortState.closed);
  }

  /// Drops everything tied to a link that is gone: the pending reply, the keys,
  /// the channel and what we know about it.
  void _invalidateSession(AppException reason) {
    final pending = _pendingResponse;
    _pendingResponse = null;
    _pendingTimer?.cancel();
    if (pending != null && !pending.isCompleted) {
      pending.completeError(reason);
    }
    _rx.reset();
    _requestReplayed = false;
    _authenticated = false;
    _password = null;
    _psk = null;
    _key = null;
    _nonce = null;
    _aad = null;
    _forgetChannel();
    updateConnectedReader(null);
  }

  void _forgetChannel() {
    _channel = 0;
    _linklanChannel = null;
    _preferredChannel = 0;
    _nextStoreBlock = null;
    _channelCandidates = const <int>[];
  }

  Future<void> _releaseChannel() async {
    final channel = _channel;
    _forgetChannel();
    if (channel == 0 || !_authenticated || _linkBroken) return;
    try {
      // A re-challenge here must not start a handshake, which could open the
      // password dialog in the middle of a disconnect.
      final rsp = await _request(
        LinklanProtocol.cmdScard,
        LinklanProtocol.closeChannel(channel),
        0,
      );
      final result = LinklanProtocol.pbIntOf(_decodeReply(rsp), 2);
      if (result == 0) {
        _log.fine('Linklan: channel $channel closed');
      } else {
        _log.fine('Linklan: channel $channel close refused (result $result)');
      }
    } catch (error) {
      _log.fine('Linklan: closing channel $channel failed ($error)');
    }
  }

  /// One round trip on an explicit channel, for use while probing.
  Future<({int sw, Uint8List body})> _transmitOnce(
    int channel,
    int cla,
    int ins,
    int p1,
    int p2,
    Uint8List data, {
    int? p3,
    Duration? timeout,
  }) async {
    final response = await _request(
      LinklanProtocol.cmdScard,
      LinklanProtocol.transmitApdu(
        channel: channel,
        cla: cla,
        ins: ins,
        p1: p1,
        p2: p2,
        data: data,
        p3: p3,
      ),
      6,
      timeout,
    );
    final message = _decodeReply(response);
    final transmitApduResponse = LinklanProtocol.pbBytesOf(message, 4);
    if (transmitApduResponse == null) {
      // Bridge could not use the channel.
      final result = LinklanProtocol.pbIntOf(message, 2);
      _log.warning(
        'Linklan: SCARD reply without transmitApdu (result=$result, '
        '${response.length} B)',
      );
      if (result != 0) {
        return (sw: LinklanProtocol.swChannelNotSupported, body: Uint8List(0));
      }
      throw AppException(
        AppErrorCode.ERROR_TRANSACTION_FAILED,
        message: 'Linklan: no transmitApdu response',
      );
    }
    final inner = _decodeReply(transmitApduResponse);
    final sw1 = LinklanProtocol.unzigzag(LinklanProtocol.pbIntOf(inner, 1));
    final sw2 = LinklanProtocol.unzigzag(LinklanProtocol.pbIntOf(inner, 2));
    return (
      sw: ((sw1 & 0xff) << 8) | (sw2 & 0xff),
      body: LinklanProtocol.pbBytesOf(inner, 3) ?? Uint8List(0),
    );
  }

  Future<Uint8List> _transmitApdu(
    int cla,
    int ins,
    int p1,
    int p2,
    Uint8List data, {
    int? p3,
  }) async {
    _checkLink();
    final store = ins == 0xe2;
    // ProfileManager may already have split this command. A continuation is
    // meaningful only on the channel that accepted its preceding block.
    final continuing = store && _nextStoreBlock == p2;
    _nextStoreBlock = null;
    if (store && p2 != 0 && !continuing) {
      throw AppException(
        AppErrorCode.ERROR_TRANSACTION_FAILED,
        message: 'Linklan: STORE DATA chain is not active at block $p2',
      );
    }
    if (store && data.length > LinklanProtocol.storeDataBlockSize) {
      if (continuing || p1 != LinklanProtocol.storeDataLastBlockP1) {
        throw AppException(
          AppErrorCode.ERROR_TRANSACTION_FAILED,
          message: 'Linklan: cannot split a caller-supplied STORE DATA block',
        );
      }
      var lastResponse = Uint8List.fromList([
        LinklanProtocol.swInstructionNotSupported >> 8,
        LinklanProtocol.swInstructionNotSupported & 0xff,
      ]);
      for (final block in LinklanProtocol.storeDataBlocks(data)) {
        lastResponse = await _transmitApdu(
          cla,
          ins,
          block.p1,
          block.p2,
          block.chunk,
        );
        if (lastResponse[lastResponse.length - 2] != 0x90 ||
            lastResponse.last != 0) {
          break;
        }
      }
      return lastResponse;
    }

    await _awaitRefreshWindow();
    await _ensureChannel();
    var target = _channel;
    // Certificate checks need longer than the frame timeout.
    final frameTimeout = ins == 0xe2 ? const Duration(seconds: 60) : null;
    var result = await _transmitOnce(
      target,
      cla,
      ins,
      p1,
      p2,
      data,
      p3: p3,
      timeout: frameTimeout,
    );
    // Retry 6985 only while the card may still be settling after our reset.
    for (var attempt = 0; attempt < 6 && result.sw == 0x6985; attempt++) {
      final resetAt = _lastResetAt;
      if (resetAt == null ||
          DateTime.now().difference(resetAt) > const Duration(seconds: 45)) {
        break;
      }
      _log.fine('Linklan: card still settling (6985), retrying');
      await _operation!.delay(const Duration(seconds: 2));
      result = await _transmitOnce(
        target,
        cla,
        ins,
        p1,
        p2,
        data,
        p3: p3,
        timeout: frameTimeout,
      );
    }
    if (LinklanProtocol.isChannelRejection(result.sw) && !continuing) {
      // Try the other channel reading before paying for a re-open.
      for (final candidate in _channelCandidates) {
        if (candidate == target) continue;
        final retryResult = await _transmitOnce(
          candidate,
          cla,
          ins,
          p1,
          p2,
          data,
          p3: p3,
          timeout: frameTimeout,
        );
        if (!LinklanProtocol.isChannelRejection(retryResult.sw)) {
          _log.info('Linklan: channel $candidate serves the APDUs');
          _preferredChannel = candidate;
          _channel = candidate;
          _channelCandidates = <int>[candidate];
          target = candidate;
          result = retryResult;
          break;
        }
      }
      if (LinklanProtocol.isChannelRejection(result.sw)) {
        _log.info(
          'Linklan: channel $target rejected the APDU, opening a fresh one',
        );
        await _releaseChannel();
        await _ensureChannel();
        target = _channel;
        result = await _transmitOnce(
          target,
          cla,
          ins,
          p1,
          p2,
          data,
          p3: p3,
          timeout: frameTimeout,
        );
      }
    }
    _log.fine(
      'Linklan APDU ins=${ins.toRadixString(16)} ch=$target -> '
      'SW ${result.sw.toRadixString(16)} (${result.body.length} B)',
    );

    // 61xx: fetch the rest with GET RESPONSE (CLA 00, INS C0, Le in P3).
    if (result.sw >> 8 == LinklanProtocol.swMoreData) {
      result = await _getResponse(target, result);
    }
    final sw1 = result.sw >> 8;
    final sw2 = result.sw & 0xff;

    // 91xx = success + REFRESH; report 90 00 and drop the channel.
    if (sw1 == LinklanProtocol.swSuccessRefresh) {
      _log.info('Linklan: SW 91xx (refresh requested), dropping the channel');
      _refreshingUntil = DateTime.now().add(
        const Duration(seconds: LinklanProtocol.refreshSettleSeconds),
      );
      // The card is re-initialising and will not answer a closeChannel. Drop our
      // side only; the reset below recycles the card's table.
      _forgetChannel();
      return Uint8List.fromList([
        ...result.body,
        LinklanProtocol.swSuccess,
        0x00,
      ]);
    }
    if (LinklanProtocol.isChannelRejection(result.sw)) {
      await _releaseChannel();
    } else if (result.sw == 0x9000 &&
        store &&
        p1 == LinklanProtocol.storeDataChainedP1) {
      _nextStoreBlock = (p2 + 1) & 0xff;
    }
    return Uint8List.fromList([...result.body, sw1, sw2]);
  }

  Future<({int sw, Uint8List body})> _getResponse(
    int target,
    ({int sw, Uint8List body}) first,
  ) async {
    final collected = BytesBuilder(copy: false)..add(first.body);
    final candidates = <int>{target, 1, 0}.iterator..moveNext();
    var le = first.sw & 0xff;
    for (var round = 0; round < 2048; round++) {
      final next = await _transmitOnce(
        candidates.current,
        0,
        0xc0,
        0,
        0,
        Uint8List(0),
        p3: le,
        timeout: const Duration(seconds: 3),
      );
      final verdict = classifyContinuation(next.sw);
      if (verdict.kind == 'refused') {
        if (candidates.moveNext()) continue;
        final error = AppException(
          AppErrorCode.ERROR_TRANSACTION_FAILED,
          message:
              'Linklan: GET RESPONSE refused (SW ${next.sw.toRadixString(16)})',
        );
        _breakLink(error);
        throw error;
      }
      // A corrected Le applies to this channel. Short Le=256 is encoded as zero.
      if (verdict.kind != 'correctedLe') collected.add(next.body);
      if (verdict.kind == 'final') {
        return (sw: next.sw, body: collected.takeBytes());
      }
      le = verdict.length;
    }
    final error = AppException(
      AppErrorCode.ERROR_TRANSACTION_FAILED,
      message: 'Linklan: too many GET RESPONSE steps',
    );
    _breakLink(error);
    throw error;
  }

  @override
  Future<Uint8List> sendRawApdu(Uint8List apdu) async => throw UnsupportedError(
    'Linklan only supports APDUs on the ISD-R channel',
  );

  @override
  Future<Channel> openChannel({List<String>? aids}) async {
    return await runExclusive(() async {
      if (aids != null &&
          aids.isNotEmpty &&
          !aids.any(
            (aid) => aid.trim().toUpperCase() == LinklanProtocol.isdrAid,
          )) {
        throw AppException(
          AppErrorCode.ERROR_APPLICATION_NOT_FOUND,
          message: 'Linklan can only open ISD-R',
        );
      }
      _checkLink();
      await _awaitRefreshWindow();
      await _ensureChannel();
      _linklanChannel ??= _LinklanChannel(this, LinklanProtocol.isdrAid);
      return _linklanChannel!;
    });
  }

  /// Applies the REFRESH the card asks for after a switch.
  @override
  Future<void> resetAfterProfileSwitch() async {
    await runExclusive(() async {
      if (!_authenticated) {
        // The refresh invalidated the session, but the card still needs the
        // reset; re-handshake on the same link first.
        try {
          await _authenticateWithPasswordPrompt();
        } catch (error) {
          _operation!.check();
          _log.warning('Linklan: handshake before reset failed ($error)');
          return;
        }
      }
      try {
        await _request(
          LinklanProtocol.cmdDevice,
          LinklanProtocol.pbInt(1, 3, always: true),
        );
        _log.info('Linklan: resetDevice sent, refresh applied');
      } catch (error) {
        _operation!.check();
        _log.warning('Linklan: resetDevice failed ($error)');
      }
      // The reset drops the card's channels. Do not send CLOSE while it settles.
      _forgetChannel();
      _authenticated = false;
      _refreshingUntil = DateTime.now().add(
        const Duration(seconds: LinklanProtocol.refreshSettleSeconds),
      );
      await _awaitRefreshWindow();
      _lastResetAt = DateTime.now();
      _log.info('Linklan: card settled after reset');
      // The reset dropped the session, and the first APDU that races it is
      // answered with something that is not an APDU response. Handshake here so
      // callers start from a live link.
      try {
        await _authenticateWithPasswordPrompt();
        await _replayPendingRequest(reauthBudget: 0);
      } catch (error) {
        _operation!.check();
        _log.warning('Linklan: handshake after reset failed ($error)');
      }
    });
  }

  @override
  Future<void> cleanupChannels() async {
    // Closing our only channel here produced 6881 on the next command.
  }

  @override
  Future<void> disconnect() async {
    _disconnectRequested = true;
    await runExclusive(() async {
      await _tearDown(emitClosed: true);
    });
  }

  @override
  Future<void> reconnect() => runExclusive(() async {
    final reader = connectedReader;
    _linkBroken = true;
    await _tearDown(emitClosed: false);
    if (reader != null) await connect(reader);
  });

  @override
  void interruptPendingOperation() {
    final error = AppException(
      AppErrorCode.ERROR_BLUETOOTH_TIMEOUT,
      message: 'Linklan operation interrupted',
    );
    _operation?.cancel(error);
    if (_device != null) _breakLink(error);
  }

  Future<void> _tearDown({required bool emitClosed}) async {
    await _releaseChannel();
    ++_linkGeneration;
    _invalidateSession(
      AppException(AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED),
    );
    await _notifySub?.cancel();
    _notifySub = null;
    await _connSub?.cancel();
    _connSub = null;
    try {
      if (!_linkBroken && _notifyChar != null) {
        await _notifyChar!.setNotifyValue(false);
      }
    } catch (_) {
      // ignore
    }
    _writeChar = null;
    _notifyChar = null;
    _transportReady = false;
    try {
      await (_disconnecting ?? _device?.disconnect());
    } catch (_) {
      // Already disconnected.
    }
    _disconnecting = null;
    _device = null;
    _deviceId = null;
    _deviceName = null;
    if (emitClosed) _stateController.add(EuiccPortState.closed);
  }

  Future<String?> _promptForPassword() async {
    final context = navigatorKey.currentContext;
    if (context == null) return null;
    final l10n = AppLocalizations.of(context)!;
    var password = '';
    var obscure = true;
    final navigator = Navigator.of(context, rootNavigator: true);
    final route = DialogRoute<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.remoteReaderPassword),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.authFailedCheckPassword),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: l10n.password,
                  hintText: l10n.linklanPasswordHint,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                ),
                obscureText: obscure,
                autofocus: true,
                onChanged: (value) => password = value,
                onSubmitted: (value) => Navigator.pop(context, value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, password),
              child: Text(l10n.ok),
            ),
          ],
        ),
      ),
    );
    _checkLink();
    try {
      return await _operation!.waitFor(navigator.push(route));
    } finally {
      if (route.isActive) navigator.removeRoute(route);
    }
  }
}

/// Shared by nested calls holding the same exclusive lock.
class _LinklanOperation {
  AppException? _error;
  final _waiters = <VoidCallback>{};

  void check() {
    final error = _error;
    if (error != null) throw error;
  }

  void cancel(AppException reason) {
    if (_error != null) return;
    _error = reason;
    for (final wake in _waiters) {
      wake();
    }
  }

  Future<T> waitFor<T>(Future<T> work) async {
    if (_error != null) {
      work.ignore();
      throw _error!;
    }
    final stopped = Completer<T>();
    void wake() => stopped.completeError(_error!);
    _waiters.add(wake);
    try {
      final result = await Future.any([work, stopped.future]);
      check();
      return result;
    } finally {
      _waiters.remove(wake);
    }
  }

  Future<void> delay(Duration duration) async {
    final done = Completer<void>();
    final timer = Timer(duration, done.complete);
    try {
      await waitFor(done.future);
    } finally {
      timer.cancel();
    }
  }
}

class _LinklanChannel implements Channel {
  _LinklanChannel(this._adapter, this.aid)
    : _generation = _adapter._linkGeneration;

  final LinklanAdapter _adapter;
  final int _generation;

  @override
  int get channelNumber => _adapter._channel;

  @override
  final String? aid;

  @override
  Adapter get adapter => _adapter;

  @override
  Future<Uint8List> transmit(
    int cla,
    int ins,
    int p1,
    int p2, [
    Uint8List? data,
    int? le,
  ]) => _adapter.runExclusive(() async {
    if (_generation != _adapter._linkGeneration) {
      throw AppException(
        AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED,
        message: 'Linklan channel belongs to a previous connection',
      );
    }
    if (data != null && data.isNotEmpty && le != null) {
      throw UnsupportedError('Linklan cannot encode both Lc and Le');
    }
    return _adapter._transmitApdu(
      cla,
      ins,
      p1,
      p2,
      data ?? Uint8List(0),
      p3: le,
    );
  });

  @override
  Future<void> close() async {
    try {
      await _adapter.cleanupChannels();
    } catch (_) {
      // ignore
    }
  }
}

/// A password remembered for one card.
class LinklanStoredPassword {
  const LinklanStoredPassword({
    required this.deviceName,
    required this.password,
  });

  final String deviceName;
  final String password;
}

/// Reassembles length-prefixed LPAd frames from BLE notifications.
///
/// A notification can end anywhere, including inside the two-byte length prefix,
/// so chunks are accumulated until a whole frame is available.
class LinklanFrameAssembler {
  final List<int> _buffer = <int>[];
  int _expected = 0;

  /// Appends [chunk] and returns every frame it completes, in order.
  List<Uint8List> add(List<int> chunk) {
    if (chunk.isEmpty) return const <Uint8List>[];
    _buffer.addAll(chunk);
    final frames = <Uint8List>[];
    while (true) {
      if (_expected == 0) {
        if (_buffer.length < 2) break;
        _expected = (_buffer[0] << 8) | _buffer[1];
        _buffer.removeRange(0, 2);
        if (_expected == 0) continue;
      }
      if (_buffer.length < _expected) break;
      frames.add(Uint8List.fromList(_buffer.sublist(0, _expected)));
      _buffer.removeRange(0, _expected);
      _expected = 0;
    }
    return frames;
  }

  void reset() {
    _buffer.clear();
    _expected = 0;
  }
}
