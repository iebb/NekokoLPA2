import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../settings/app_settings.dart';

class OperatorIconSource {
  static final Logger _log = Logger('OperatorIconSource');
  static final OperatorIconSource _instance = OperatorIconSource._internal();

  factory OperatorIconSource() => _instance;

  OperatorIconSource._internal();

  static const String baseUrl = 'https://operator-icons.pages.dev';
  static const String catalogBaseUrl = '$baseUrl/catalog';
  static const String iconBaseUrl = '$baseUrl/icons';

  final Map<String, Future<_OperatorIconCatalog?>> _pendingCatalogLoads = {};
  final Map<String, _OperatorIconCatalog?> _catalogCache = {};

  Future<String?> resolveIconUrl({
    required String mcc,
    required String mnc,
    String? gid1,
    String? gid2,
    String? profileName,
    String? serviceProviderName,
  }) async {
    final normalizedMcc = _normalizeCode(mcc);
    if (normalizedMcc == null) return null;

    final catalog = await _loadCatalog(normalizedMcc);
    final reference = catalog?.resolve(
      mnc: mnc,
      gid1: gid1,
      gid2: gid2,
      profileName: profileName,
      serviceProviderName: serviceProviderName,
    );
    if (reference == null) return null;

    return '$iconBaseUrl/${Uri.encodeComponent(reference.scope)}/${Uri.encodeComponent(reference.name)}.png';
  }

  Future<_OperatorIconCatalog?> _loadCatalog(String mcc) {
    final cached = _catalogCache[mcc];
    if (_catalogCache.containsKey(mcc)) return Future.value(cached);

    final pending = _pendingCatalogLoads[mcc];
    if (pending != null) return pending;

    final load = _fetchCatalog(mcc);
    _pendingCatalogLoads[mcc] = load;
    return load;
  }

  Future<_OperatorIconCatalog?> _fetchCatalog(String mcc) async {
    try {
      final response = await http
          .get(
            Uri.parse('$catalogBaseUrl/$mcc.toml'),
            headers: {'User-Agent': AppSettings().userAgent},
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 404) {
        _catalogCache[mcc] = null;
        return null;
      }
      if (response.statusCode != 200) {
        _log.warning(
          'Failed to fetch operator icon catalog for $mcc: ${response.statusCode}',
        );
        return null;
      }

      final catalog = _OperatorIconCatalog.parse(response.body);
      _catalogCache[mcc] = catalog;
      return catalog;
    } catch (e) {
      _log.severe('Error fetching operator icon catalog for $mcc: $e');
      return null;
    } finally {
      _pendingCatalogLoads.remove(mcc);
    }
  }

  String? _normalizeCode(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || !RegExp(r'^\d+$').hasMatch(normalized)) {
      return null;
    }
    return normalized;
  }
}

class _OperatorIconReference {
  const _OperatorIconReference({required this.name, required this.scope});

  final String name;
  final String scope;
}

class _OperatorIconCatalog {
  _OperatorIconCatalog(this.operators);

  final List<_OperatorCatalogEntry> operators;

  static _OperatorIconCatalog parse(String source) {
    final operators = <_OperatorCatalogEntry>[];
    _OperatorCatalogEntry? currentOperator;
    _OperatorCatalogGid? currentGid;

    void finishOperator() {
      final operator = currentOperator;
      if (operator != null) operators.add(operator);
      currentOperator = null;
      currentGid = null;
    }

    for (final rawLine in const LineSplitter().convert(source)) {
      final line = _stripTomlComment(rawLine).trim();
      if (line.isEmpty) continue;

      if (line == '[[operators]]') {
        finishOperator();
        currentOperator = _OperatorCatalogEntry();
        continue;
      }

      if (line == '[[operators.gids]]') {
        final operator = currentOperator;
        if (operator == null) continue;
        currentGid = _OperatorCatalogGid();
        operator.gids.add(currentGid!);
        continue;
      }

      final separator = line.indexOf('=');
      if (separator == -1) continue;

      final key = line.substring(0, separator).trim();
      final value = line.substring(separator + 1).trim();

      final gid = currentGid;
      if (gid != null) {
        switch (key) {
          case 'gid1':
            gid.gid1 = _parseTomlString(value);
            break;
          case 'gid2':
            gid.gid2 = _parseTomlString(value);
            break;
          case 'profile_names':
            gid.profileNames = _parseTomlStringList(value);
            break;
          case 'profile_provider_names':
            gid.profileProviderNames = _parseTomlStringList(value);
            break;
        }
        continue;
      }

      final operator = currentOperator;
      if (operator == null) continue;

      switch (key) {
        case 'mnc':
          operator.mnc = _parseTomlString(value);
          break;
        case 'operator':
          operator.operatorName = _parseTomlString(value);
          break;
        case 'brand':
          operator.brand = _parseTomlString(value);
          break;
        case 'icon':
          operator.icon = _parseTomlString(value);
          break;
        case 'icon_scope':
          operator.iconScope = _parseTomlString(value);
          break;
      }
    }

    finishOperator();
    return _OperatorIconCatalog(operators);
  }

  _OperatorIconReference? resolve({
    required String mnc,
    String? gid1,
    String? gid2,
    String? profileName,
    String? serviceProviderName,
  }) {
    final mncCandidates = _mncCandidates(mnc);
    final ranked =
        operators
            .map(
              (entry) => (
                entry: entry,
                score: entry.score(
                  mncCandidates: mncCandidates,
                  gid1: gid1,
                  gid2: gid2,
                  profileName: profileName,
                  serviceProviderName: serviceProviderName,
                ),
              ),
            )
            .where((match) => match.score >= 0)
            .toList()
          ..sort((a, b) => b.score.compareTo(a.score));

    if (ranked.isEmpty) return null;

    final operator = ranked.first.entry;
    final icon = operator.icon;
    final scope = operator.iconScope;
    if (icon == null || icon.isEmpty || scope == null || scope.isEmpty) {
      return null;
    }

    return _OperatorIconReference(name: icon, scope: scope);
  }
}

class _OperatorCatalogEntry {
  String? mnc;
  String? operatorName;
  String? brand;
  String? icon;
  String? iconScope;
  final List<_OperatorCatalogGid> gids = [];

  int score({
    required Set<String> mncCandidates,
    String? gid1,
    String? gid2,
    String? profileName,
    String? serviceProviderName,
  }) {
    if (icon == null || iconScope == null || !mncCandidates.contains(mnc)) {
      return -1;
    }

    var score = 100;
    if (_matchesAnyName(profileName, serviceProviderName)) score += 20;

    final requestedGid1 = _normalizeOptional(gid1);
    final requestedGid2 = _normalizeOptional(gid2);
    if (requestedGid1 != null || requestedGid2 != null) {
      final gidMatch = gids.any(
        (gid) => gid.matches(
          gid1: requestedGid1,
          gid2: requestedGid2,
          profileName: profileName,
          serviceProviderName: serviceProviderName,
        ),
      );
      if (gidMatch) score += 30;
    }

    return score;
  }

  bool _matchesAnyName(String? profileName, String? serviceProviderName) {
    return _matchesName(profileName, operatorName) ||
        _matchesName(profileName, brand) ||
        _matchesName(serviceProviderName, operatorName) ||
        _matchesName(serviceProviderName, brand) ||
        gids.any(
          (gid) => gid.matchesName(
            profileName: profileName,
            serviceProviderName: serviceProviderName,
          ),
        );
  }
}

class _OperatorCatalogGid {
  String? gid1;
  String? gid2;
  List<String> profileNames = const [];
  List<String> profileProviderNames = const [];

  bool matches({
    String? gid1,
    String? gid2,
    String? profileName,
    String? serviceProviderName,
  }) {
    final expectedGid1 = _normalizeOptional(this.gid1);
    final expectedGid2 = _normalizeOptional(this.gid2);

    final gidsMatch =
        (expectedGid1 == null || expectedGid1 == gid1) &&
        (expectedGid2 == null || expectedGid2 == gid2);

    return gidsMatch ||
        matchesName(
          profileName: profileName,
          serviceProviderName: serviceProviderName,
        );
  }

  bool matchesName({String? profileName, String? serviceProviderName}) {
    return profileNames.any((name) => _matchesName(profileName, name)) ||
        profileProviderNames.any(
          (name) => _matchesName(serviceProviderName, name),
        );
  }
}

Set<String> _mncCandidates(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return const {};
  return {
    trimmed,
    if (trimmed.length < 2) trimmed.padLeft(2, '0'),
    if (trimmed.length < 3) trimmed.padLeft(3, '0'),
  };
}

String? _normalizeOptional(String? value) {
  final normalized = value?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) return null;
  return normalized;
}

bool _matchesName(String? candidate, String? expected) {
  final normalizedCandidate = candidate?.trim().toLowerCase();
  final normalizedExpected = expected?.trim().toLowerCase();
  if (normalizedCandidate == null ||
      normalizedCandidate.isEmpty ||
      normalizedExpected == null ||
      normalizedExpected.isEmpty) {
    return false;
  }

  return normalizedCandidate == normalizedExpected ||
      normalizedCandidate.contains(normalizedExpected) ||
      normalizedExpected.contains(normalizedCandidate);
}

String _stripTomlComment(String line) {
  var inString = false;
  var escaped = false;

  for (var i = 0; i < line.length; i++) {
    final char = line[i];
    if (escaped) {
      escaped = false;
      continue;
    }
    if (char == '\\') {
      escaped = true;
      continue;
    }
    if (char == '"') {
      inString = !inString;
      continue;
    }
    if (!inString && char == '#') {
      return line.substring(0, i);
    }
  }

  return line;
}

String? _parseTomlString(String value) {
  final trimmed = value.trim();
  if (trimmed.length < 2 || !trimmed.startsWith('"')) return null;

  try {
    final parsed = jsonDecode(trimmed);
    return parsed is String ? parsed : null;
  } catch (_) {
    return trimmed.substring(1, trimmed.length - 1);
  }
}

List<String> _parseTomlStringList(String value) {
  final matches = RegExp(r'"(?:\\.|[^"\\])*"').allMatches(value);
  return matches
      .map((match) => _parseTomlString(match.group(0) ?? ''))
      .whereType<String>()
      .toList(growable: false);
}
