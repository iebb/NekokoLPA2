import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../settings/app_settings.dart';
import '../utils/platform_adapter.dart';
import 'package:logging/logging.dart';

class UpdateInfo {
  final String version;
  final int build;
  final String url;
  final String? downloadUrl;
  final String? changelog;

  UpdateInfo({
    required this.version,
    required this.build,
    required this.url,
    this.downloadUrl,
    this.changelog,
  });
}

class UpdateService {
  static final Logger _log = Logger('UpdateService');
  static const String _configUrl = 'https://updates.lpa.ee/nlpa2.json';
  static const _certChannel = MethodChannel('ee.nekoko.certificate_plugin');

  Future<UpdateInfo?> checkForUpdates() async {
    try {
      final os = PlatformX.operatingSystem;

      // Update check only applies to Android, Windows and Linux
      if (os != 'android' && os != 'windows' && os != 'linux') {
        _log.info('Update check skipped for OS: $os');
        return null;
      }

      final response = await http.get(Uri.parse(_configUrl));
      if (response.statusCode != 200) {
        _log.warning('Failed to fetch update config: ${response.statusCode}');
        return null;
      }

      final config = jsonDecode(response.body);

      String platformKey = os;
      if (os == 'android') {
        final abis = await _getAndroidSupportedAbis();
        if (abis.isNotEmpty) {
          final firstAbi = abis.first.toLowerCase();
          if (firstAbi == 'armeabi-v7a' || firstAbi == 'armeabi') {
            platformKey = 'android-armeabi-v7a';
          }
        }
      }

      if (!config.containsKey(platformKey)) {
        if (os == 'android' &&
            platformKey != 'android' &&
            config.containsKey('android')) {
          platformKey = 'android';
        } else {
          _log.info('No update config for current platform: $platformKey');
          return null;
        }
      }

      final osConfig = config[platformKey];

      if (os == 'android') {
        return await _checkAndroidUpdate(osConfig);
      } else {
        return _checkGenericUpdate(osConfig);
      }
    } catch (e) {
      _log.warning('Error checking for updates: $e');
      return null;
    }
  }

  Future<UpdateInfo?> _checkAndroidUpdate(dynamic osConfig) async {
    final variant = AppSettings().variant;

    // Check if configuration exists for Android
    if (osConfig is! Map) {
      _log.info('Invalid update config format for Android');
      return null;
    }

    final currentHashes = await _getAndroidSignatures();
    final currentBuildString = AppSettings().buildNumber;
    final currentBuild = int.tryParse(currentBuildString) ?? 0;

    UpdateInfo? bestMatch;
    int maxBuild = currentBuild;

    // Handle new format (flat dictionary with keys "variant-sigs")
    // or nested format (dict with variant keys pointing to list or dict)

    // First, flatten the candidates list from the config structure
    final candidates = <Map<String, dynamic>>[];

    osConfig.forEach((key, value) {
      // New format: key is "variant-sig1-sig2..."
      if (key.toString().startsWith('$variant-') || key.toString() == variant) {
        if (value is Map) {
          candidates.add(Map<String, dynamic>.from(value));
        } else if (value is List) {
          // Old format: key is just variant, value is list of releases
          for (final item in value) {
            if (item is Map) candidates.add(Map<String, dynamic>.from(item));
          }
        }
      }
    });

    for (final release in candidates) {
      final build = release['build'] as int? ?? 0;

      // If we already found a higher build that matches our signature, skipping lower ones
      if (build <= maxBuild) continue;

      // Match signatures: release must have matching signature or no signatures restricted
      final List<dynamic>? allowedSignatures = release['signatures'];
      bool sigMatch = false;

      if (allowedSignatures == null || allowedSignatures.isEmpty) {
        // Empty signature list in config means no restriction
        sigMatch = true;
      } else {
        for (final sig in currentHashes) {
          if (allowedSignatures.any(
            (s) => s.toString().toUpperCase() == sig.toUpperCase(),
          )) {
            sigMatch = true;
            break;
          }
        }
      }

      if (sigMatch) {
        maxBuild = build;
        bestMatch = _mapToUpdateInfo(release);
        _log.info(
          'Found candidate update: v${bestMatch.version} b${bestMatch.build} for variant $variant',
        );
      }
    }

    if (bestMatch == null) {
      _log.info(
        'No signature-matching updates found for variant $variant higher than $currentBuild',
      );
    }

    return bestMatch;
  }

  UpdateInfo? _checkGenericUpdate(dynamic osConfig) {
    if (osConfig is! Map) return null;

    // Try to find variant-specific config, then "std", then fallback to direct
    final variant = AppSettings().variant;
    dynamic targetConfig;

    if (variant.isNotEmpty && osConfig.containsKey(variant)) {
      targetConfig = osConfig[variant];
    } else if (osConfig.containsKey('std')) {
      targetConfig = osConfig['std'];
    } else {
      targetConfig = osConfig;
    }

    if (targetConfig is! Map) return null;

    final latestBuild = targetConfig['build'] as int? ?? 0;
    final currentBuild = int.tryParse(AppSettings().buildNumber) ?? 0;

    if (latestBuild > currentBuild) {
      return _mapToUpdateInfo(targetConfig);
    }
    return null;
  }

  UpdateInfo _mapToUpdateInfo(dynamic data) {
    return UpdateInfo(
      version: data['version'] ?? 'Unknown',
      build: data['build'] ?? 0,
      url: data['url'] ?? '',
      downloadUrl: data['download_url'],
      changelog: data['changelog'],
    );
  }

  Future<List<String>> _getAndroidSignatures() async {
    try {
      final Map<dynamic, dynamic>? result = await _certChannel.invokeMethod(
        'getCertificateHashes',
      );
      final List<dynamic>? sha1List = result?['sha1'];
      if (sha1List != null) {
        return sha1List.map((e) => e.toString().toUpperCase()).toList();
      }
    } catch (e) {
      _log.warning('Failed to get Android signatures: $e');
    }
    return [];
  }

  Future<List<String>> _getAndroidSupportedAbis() async {
    try {
      final List<dynamic>? result = await _certChannel.invokeMethod('getAbi');
      if (result != null) {
        return result.map((e) => e.toString()).toList();
      }
    } catch (e) {
      _log.warning('Failed to get Android ABIs: $e');
    }
    return [];
  }
}
