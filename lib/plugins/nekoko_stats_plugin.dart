import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../models/euicc_profile.dart';
import '../settings/app_settings.dart';
import '../utils/platform_adapter.dart';
import 'plugin_base.dart';

class NekokoStatsPlugin extends ProfilePlugin {
  static final Logger _log = Logger('NekokoStatsPlugin');
  static const String _statsBaseUrl = 'https://nlpa-data.nekoko.ee';
  static const String _successUrl = '$_statsBaseUrl/reporting/v3/success';
  static const String _failUrl = '$_statsBaseUrl/reporting/v3/fail';

  @override
  String get id => 'nekoko_stats';

  @override
  String get name => 'Nekoko Statistics';

  @override
  bool isMatch(EuiccProfile profile) => false;

  @override
  Future<void> onInstallationReported(InstallationReportContext report) async {
    if (!AppSettings().enableNekokoStats) return;
    if (report.authBefore == null) return;

    try {
      final payload = await _buildPayload(report);
      final url = report.isSuccess ? _successUrl : _failUrl;

      await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'User-Agent': AppSettings().userAgent,
              'X-App-Version': AppSettings().version,
              'X-App-Build': AppSettings().buildNumber,
              'X-App-OS': PlatformX.operatingSystem,
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
      _log.info('Installation stats reported to $url');
    } catch (e) {
      _log.warning('Failed to report stats: $e');
    }
  }

  Future<Map<String, dynamic>> _buildPayload(
    InstallationReportContext report,
  ) async {
    final payload = <String, dynamic>{
      'metadata': base64Encode(
        report
                .session
                ?.authenticateClientResponse
                ?.authenticateClientOk
                ?.profileMetadata
                ?.encode() ??
            [],
      ),
      'auth_before': base64Encode(report.authBefore!.encode()),
    };

    if (report.authAfter != null) {
      payload['auth_after'] = base64Encode(report.authAfter!.encode());
    }

    if (report.installResult != null) {
      payload['install_result'] = report.installResult;
    }

    if (report.bppSize != null) {
      payload['bpp_size'] = report.bppSize;
    }

    final notification = report.notification;
    if (notification != null) {
      payload['notification'] = base64Encode(notification.encode());
      final error = notification
          .profileInstallationResult
          ?.profileInstallationResultData
          ?.finalResult
          ?.errorResult;
      if (error != null) {
        payload['bpp_command_id'] = error.bppCommandId?.name;
        payload['error_reason'] = error.errorReason?.name;
      }
    }

    payload.addAll(await _collectDeviceInfoForStats());

    return payload;
  }

  Future<Map<String, dynamic>> _collectDeviceInfoForStats() async {
    if (AppSettings().variant != 'esim9') return {};

    try {
      final deviceInfo = DeviceInfoPlugin();
      String? brand;
      String? model;

      if (PlatformX.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        brand = androidInfo.brand;
        model = androidInfo.model;
      } else if (PlatformX.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        brand = 'Apple';
        model = iosInfo.utsname.machine.isNotEmpty
            ? iosInfo.utsname.machine
            : iosInfo.model;
      } else {
        return {};
      }

      final result = <String, dynamic>{};
      final normalizedBrand = _nonEmptyString(brand);
      final normalizedModel = _nonEmptyString(model);

      if (normalizedBrand != null) {
        result['device_brand'] = normalizedBrand;
      }
      if (normalizedModel != null) {
        result['device_model'] = normalizedModel;
      }

      return result;
    } catch (e) {
      _log.fine('Failed to collect 9e device info: $e');
      return {};
    }
  }

  String? _nonEmptyString(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
