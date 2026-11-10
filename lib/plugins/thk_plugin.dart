import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'plugin_base.dart';
import '../models/euicc_profile.dart';
import '../services/card_status_cache.dart';
import '../services/database_service.dart';
import 'package:logging/logging.dart';
import 'package:dlibphonenumber/dlibphonenumber.dart';
import '../models/profile_card_bottom_data.dart';

class ThkPlugin extends ProfilePlugin {
  static final Logger _log = Logger('ThkPlugin');

  @override
  String get id => 'thk_query';

  @override
  String get name => '3HK Query';

  @override
  bool isMatch(EuiccProfile profile) {
    String iccid = profile.iccid;
    // 3HK usually 8985231. 8985203 is also used for HK/Macau.
    return iccid.startsWith('8985231') || iccid.startsWith('8985203');
  }

  @override
  Future<void> onProfilesLoaded(
    String eid,
    List<EuiccProfile> profiles, {
    VoidCallback? onUpdate,
  }) async {
    final matched = profiles.where((p) => isMatch(p)).toList();
    if (matched.isEmpty) return;

    for (final profile in matched) {
      // Trigger async fetch if not recently updated
      // Await and signal update for immediate UI refresh if data changes
      await _fetchStatus(profile.iccid);
      onUpdate?.call();
    }
  }

  Future<void> _fetchStatus(String iccid) async {
    final cacheKey = '${id}_$iccid';
    // Check if we already have valid data
    final cached = await CardStatusCache().getCardStatus(cacheKey);
    if (cached != null) {
      // You could add timestamp check here if needed
      return;
    }

    try {
      String choppedIccid = iccid;
      if (choppedIccid.toUpperCase().endsWith('F')) {
        choppedIccid = choppedIccid.substring(0, choppedIccid.length - 1);
      }

      final uri = Uri.parse(
        'https://three.com.hk/account-pro/sim/getMsisdnByIccid?iccid=$choppedIccid',
      );

      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent': 'Mozilla/5.0',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json is Map<String, dynamic>) {
          // Basic normalization
          if (json.containsKey('msisdn')) {
            String? msisdn = json['msisdn']?.toString();
            if (msisdn != null &&
                msisdn.isNotEmpty &&
                !msisdn.startsWith('+')) {
              json['msisdn'] = '+852$msisdn';
            }
          }

          // Save to database/cache
          await DatabaseService().saveCardStatus(
            cacheKey,
            jsonEncode(json),
            DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
          );
          CardStatusCache().updateCache(cacheKey, json);
        }
      }
    } catch (e) {
      _log.warning('Failed to fetch 3HK status for $iccid: $e');
    }
  }

  @override
  ProfileCardBottomData? getProfileCardBottomData(EuiccProfile profile) {
    if (!isMatch(profile)) return null;

    final cacheKey = '${id}_${profile.iccid}';
    final data = CardStatusCache().getCardStatusSync(cacheKey);
    if (data == null) return null;

    String? msisdn = data['msisdn'] as String? ?? data['number'] as String?;
    final lineExpiry =
        data['line_expiry'] as String? ?? data['expireDate'] as String?;
    final packages = data['packages'] as List<dynamic>?;

    if (msisdn == null &&
        lineExpiry == null &&
        (packages == null || packages.isEmpty)) {
      return null;
    }

    // Format phone number
    String? formattedNumber;
    if (msisdn != null && msisdn.isNotEmpty) {
      try {
        final util = PhoneNumberUtil.instance;
        final parsed = util.parse(
          msisdn.startsWith('+') ? msisdn : '+$msisdn',
          null,
        );
        formattedNumber = util.format(parsed, PhoneNumberFormat.international);
      } catch (_) {
        formattedNumber = msisdn.startsWith('+') ? msisdn : '+$msisdn';
      }
    }

    final List<ProfilePackage> packageList = [];
    if (packages != null && packages.isNotEmpty) {
      for (var pkg in packages) {
        final name = pkg['name']?.toString() ?? 'Data';
        final totalGB = (pkg['total'] as num?)?.toDouble() ?? 0.0;
        final usedGB = (pkg['used'] as num?)?.toDouble() ?? 0.0;
        final expiry = pkg['expiry']?.toString();

        packageList.add(
          ProfilePackage(
            name: name,
            totalBytes: totalGB * 1024 * 1024 * 1024,
            usedBytes: usedGB * 1024 * 1024 * 1024,
            expiry: expiry,
          ),
        );
      }
    }

    return ProfileCardBottomData(
      themeColor: Colors.green,
      phoneNumber: formattedNumber,
      lineExpiry: lineExpiry,
      balance: null,
      packages: packageList,
    );
  }
}
