import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart';
import '../adapter/euicc_adapter.dart';
import '../plugins/session_plugin.dart';
import '../utils/hex_utils.dart';

import '../utils/apdu_exception.dart';
import 'package:logging/logging.dart';

class GmDatabase {
  static final GmDatabase _instance = GmDatabase._internal();
  factory GmDatabase() => _instance;
  GmDatabase._internal();

  Database? _db;
  Future<Database>? _opening;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    try {
      return _db = await (_opening ??= _initDb());
    } finally {
      _opening = null;
    }
  }

  Future<Database> _initDb() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final path = p.join(docsDir.path, 'gm_plugin_v2.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE psk_cache (
            eid TEXT PRIMARY KEY,
            psk TEXT,
            lastUpdated INTEGER
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('DROP TABLE IF EXISTS eid_iccid_mapping');
          await db.execute('DROP TABLE IF EXISTS psk_cache');
          await db.execute('''
            CREATE TABLE psk_cache (
              eid TEXT PRIMARY KEY,
              psk TEXT,
              lastUpdated INTEGER
            )
          ''');
        }
      },
    );
  }

  Future<void> savePsk(String eid, String pskHex) async {
    final db = await database;
    await db.insert('psk_cache', {
      'eid': eid,
      'psk': pskHex,
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getPsk(String eid) async {
    final db = await database;
    final maps = await db.query(
      'psk_cache',
      where: 'eid = ?',
      whereArgs: [eid],
    );
    if (maps.isNotEmpty) {
      return maps.first['psk'] as String?;
    }
    return null;
  }
}

class GmPlugin extends SessionPlugin {
  @override
  String get id => 'gm_plugin';

  static final Logger _log = Logger('GmPlugin');

  /// The service that hands out a GM card's PSK, queried with `?eid=`. It is
  /// supplied at build time (`--dart-define=GM_PSK_URL=...`) rather than kept
  /// in the source; a build without it only uses PSKs already cached here.
  static const String _pskUrl = String.fromEnvironment('GM_PSK_URL');

  GmPlugin();

  String? _lastEid;
  Uint8List? _lastChallenge;

  @override
  Future<bool> isInterested(Adapter adapter, String? eid) async {
    _lastEid = eid;

    if (eid != null) {
      if (_isGmEid(eid)) {
        _log.info("GmPlugin: Interested in supported EID");
        return true;
      }
    }

    return false;
  }

  @override
  Future<void> beforeCommand(
    String command,
    Map<String, dynamic> params,
    Channel channel,
  ) async {
    if (command == 'authenticateServer' && _isGmEid(_lastEid)) {
      if (_lastChallenge != null) {
        _log.info(
          "GmPlugin: Attempting BF71 Auth due to authenticateServer command",
        );
        try {
          await _performBf71Auth(_lastChallenge!, _lastEid!, channel);
        } catch (e) {
          _log.warning("GmPlugin: BF71 Auth attempt failed: $e");
        }
      }
    }
  }

  @override
  Future<void> afterCommand(
    String command,
    Map<String, dynamic> params,
    dynamic result,
    Channel channel,
  ) async {
    if (command == 'getEuiccChallenge' && result is Uint8List) {
      _lastChallenge = result;
    }

    if (command == 'authenticateServer' && result is ApduException) {
      if (result.sw1 == 0x69 && result.sw2 == 0x82) {
        if (_isGmEid(_lastEid)) {
          await _activateGmFlow(channel);
        }
      }
    }
  }

  Future<void> _activateGmFlow(Channel channel) async {
    final currentEid = channel.adapter.currentEid ?? _lastEid ?? '';
    if (currentEid.isEmpty) {
      _log.warning("GmPlugin: Cannot activate GM flow, EID missing.");
      return;
    }

    _log.info("GmPlugin: Activating GM flow");
    final pskData = await _fetchPsk(eid: currentEid, channel: channel);
    if (pskData != null) {
      _log.info("GmPlugin: Successfully fetched PSK for GM flow");
    } else {
      _log.warning("GmPlugin: Failed to fetch PSK for GM flow");
    }
  }

  Future<void> _performBf71Auth(
    Uint8List challenge,
    String eid,
    Channel channel,
  ) async {
    _log.info("GmPlugin: Performing BF71 Auth");
    final psk = await _fetchPsk(eid: eid, channel: channel);
    if (psk == null) {
      throw Exception("GmPlugin: Failed to fetch PSK");
    }

    final random = Random.secure();
    final rnHost = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      rnHost[i] = random.nextInt(256);
    }

    final authData = Uint8List(16);
    authData.setRange(0, 8, challenge.sublist(0, 8));
    authData.setRange(8, 16, rnHost.sublist(0, 8));

    final skRaw = _aesCbcEncrypt(psk, Uint8List(16), authData);

    final mac = _calcHostMac(skRaw, challenge);

    final builder = BytesBuilder();
    builder.addByte(0x80);
    builder.addByte(0x04);
    builder.add(mac);
    builder.addByte(0x81);
    builder.addByte(rnHost.length);
    builder.add(rnHost);
    final payload = builder.toBytes();

    final builderFull = BytesBuilder();
    builderFull.addByte(0xBF);
    builderFull.addByte(0x71);
    builderFull.addByte(payload.length);
    builderFull.add(payload);
    final fullData = builderFull.toBytes();

    final response = await channel.transmit(0x81, 0xE2, 0x91, 0x00, fullData);

    if (response.length >= 2) {
      final sw1 = response[response.length - 2];
      final sw2 = response[response.length - 1];
      if (sw1 != 0x90 || sw2 != 0x00) {
        throw Exception(
          "BF71 Auth APDU Failed: ${sw1.toRadixString(16)}${sw2.toRadixString(16)}",
        );
      }
    } else {
      throw Exception("Invalid response from BF71 command");
    }
  }

  Future<Uint8List?> _fetchPsk({required String eid, Channel? channel}) async {
    // 1. Try local database cache
    final cachedPsk = await GmDatabase().getPsk(eid);
    if (cachedPsk != null) {
      _log.info("GmPlugin: Found cached PSK");
      return HexUtils.hexToBytes(cachedPsk);
    }

    _log.info("GmPlugin: PSK not in cache, attempting query...");

    // 2. Query worker
    if (_pskUrl.isEmpty) {
      _log.warning("GmPlugin: No PSK service in this build (GM_PSK_URL)");
      return null;
    }
    final url = Uri.parse(_pskUrl).replace(queryParameters: {'eid': eid});

    _log.info("GmPlugin: Requesting PSK from worker");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pskStr = data['psk'] as String?;
        if (pskStr != null) {
          String pskHex = pskStr;
          if (pskStr.contains(',')) {
            pskHex = pskStr.split(',')[1];
          }
          _log.info("GmPlugin: Successfully obtained PSK from worker");
          await GmDatabase().savePsk(eid, pskHex);
          return HexUtils.hexToBytes(pskHex);
        } else {
          _log.warning("GmPlugin: Worker returned 200 but no PSK in body");
        }
      } else {
        _log.warning("GmPlugin: Worker returned status ${response.statusCode}");
      }
    } catch (_) {
      _log.severe("GmPlugin: Error querying worker");
    }
    return null;
  }

  bool _isGmEid(String? eid) {
    if (eid == null) return false;
    return eid.compareTo('89086029202200002122000030900000') >= 0 &&
        eid.compareTo('89086029202200002122000040000000') <= 0;
  }

  Uint8List _aesCbcEncrypt(Uint8List key, Uint8List iv, Uint8List data) {
    final engine = AESEngine();
    final cipher = CBCBlockCipher(engine);
    cipher.init(true, ParametersWithIV(KeyParameter(key), iv));
    final out = Uint8List(data.length);
    var offset = 0;
    while (offset < data.length) {
      offset += cipher.processBlock(data, offset, out, offset);
    }
    return out;
  }

  Uint8List _calcHostMac(Uint8List sessionKey, Uint8List challenge) {
    final ct = _aesCbcEncrypt(sessionKey, Uint8List(16), challenge);
    final res = Uint8List(8);
    for (int i = 0; i < 8; i++) {
      res[i] = ct[i] ^ ct[i + 8];
    }
    return res.sublist(0, 4);
  }
}
