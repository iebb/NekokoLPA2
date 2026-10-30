import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:logging/logging.dart';
import 'webcard_js.dart';
import '../euicc_adapter.dart';

class WebCardAdapter extends BaseAdapter {
  static final Logger _log = Logger('WebCardAdapter');
  final Map<String, WebCardReader> _readerObjects = {};
  WebCardReader? _currentReaderObject;
  String? _lastAtr;

  final StreamController<EuiccPortState> _stateController =
      StreamController<EuiccPortState>.broadcast();

  WebCardAdapter() : super(_log);

  @override
  Stream<EuiccPortState> get stateStream => _stateController.stream;

  @override
  bool get requiresRefresh => false;

  @override
  String? get lastAtr => _lastAtr;

  @override
  Future<List<Reader>> listReaders({bool force = false}) async {
    final wc = webCard;
    if (wc == null) {
      return [];
    }

    try {
      _readerObjects.clear();
      final readersJS = await wc.readers().toDart;
      final readers = readersJS.toDart;

      final results = <Reader>[];
      for (var i = 0; i < readers.length; i++) {
        final r = readers[i];
        final name = r.name;
        _readerObjects[name] = r;
        results.add(Reader(id: "webcard:$name", name: name, source: this));
      }
      return results;
    } catch (e) {
      _log.severe("Error listing WebCard readers: $e");
      return [];
    }
  }

  @override
  Future<void> connect(Reader reader) async {
    return runExclusive(() async {
      final name = reader.id.replaceFirst("webcard:", "");
      final r = _readerObjects[name];
      if (r == null) throw Exception("Reader not found");

      try {
        final jsAtr = await r.connect(true).toDart;
        _lastAtr = jsAtr.toDart;
        _currentReaderObject = r;
        updateConnectedReader(reader);
        _stateController.add(EuiccPortState.open);
      } catch (e) {
        _log.severe("Failed to connect to WebCard: $e");
        rethrow;
      }
    });
  }

  @override
  Future<void> disconnect() async {
    return runExclusive(() async {
      if (_currentReaderObject != null) {
        try {
          await _currentReaderObject!.disconnect().toDart;
        } catch (e) {
          _log.warning("Error disconnecting from WebCard: $e");
        }
        _currentReaderObject = null;
      }
      _lastAtr = null;
      updateConnectedReader(null);
      _stateController.add(EuiccPortState.closed);
    });
  }

  @override
  bool get fallbackToBasicChannelOnSelect6881 => true;

  @override
  Future<Channel> openChannel({List<String>? aids}) async {
    return await openLogicalChannel(aids: aids);
  }

  @override
  Future<Uint8List> sendRawApdu(Uint8List apdu) async {
    if (_currentReaderObject == null) throw Exception("Not connected");

    try {
      final capdu = hex.encode(apdu);
      final jsResult = await _currentReaderObject!.transceive(capdu).toDart;
      final rapdu = jsResult.toDart;
      return Uint8List.fromList(hex.decode(rapdu));
    } catch (e) {
      _log.severe("WebCard transceive error: $e");
      rethrow;
    }
  }
}
