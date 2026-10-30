import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../settings/app_settings.dart';
import '../utils/platform_adapter.dart';
import 'package:logging/logging.dart';
import 'update_feed.dart';

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
        return await _checkGenericUpdate(osConfig);
      }
    } catch (e) {
      _log.warning('Error checking for updates: $e');
      return null;
    }
  }

  Future<UpdateInfo?> _checkAndroidUpdate(dynamic osConfig) async {
    // A separate package may share feature flags without sharing APK updates.
    const channel = String.fromEnvironment('APP_UPDATE_CHANNEL');
    final variant = channel.isEmpty ? AppSettings().variant : channel;

    // Check if configuration exists for Android
    if (osConfig is! Map) {
      _log.info('Invalid update config format for Android');
      return null;
    }

    final selected = UpdateFeed.selectAndroid(
      osConfig,
      variant: variant,
      signatures: await _getAndroidSignatures(),
      currentBuild: await _getCurrentBuild(),
    );
    return selected == null ? null : _mapToUpdateInfo(selected);
  }

  Future<UpdateInfo?> _checkGenericUpdate(dynamic osConfig) async {
    if (osConfig is! Map) return null;
    final selected = UpdateFeed.selectDesktop(
      osConfig,
      variant: AppSettings().variant,
      currentBuild: await _getCurrentBuild(),
    );
    return selected == null ? null : _mapToUpdateInfo(selected);
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

  Future<int> _getCurrentBuild() async {
    final settingsBuild = int.tryParse(AppSettings().buildNumber) ?? 0;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final packageBuild = int.tryParse(packageInfo.buildNumber);
      if (packageBuild != null && packageBuild > 0) {
        if (settingsBuild > 0 && packageBuild != settingsBuild) {
          _log.info(
            'Package build $packageBuild differs from embedded build $settingsBuild; using package build for update comparison',
          );
        }
        return packageBuild;
      }
    } catch (e) {
      _log.warning('Failed to get package build number: $e');
    }

    return settingsBuild;
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
