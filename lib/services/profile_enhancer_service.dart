import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../settings/app_settings.dart';
import 'database_service.dart';
import 'card_status_cache.dart';

class ProfileEnhancerService {
  static final Logger _log = Logger('ProfileEnhancerService');
  static final ProfileEnhancerService _instance =
      ProfileEnhancerService._internal();

  factory ProfileEnhancerService() => _instance;

  ProfileEnhancerService._internal();

  /// Checks if status enhancement is needed and fetches metadata if possible.
  /// Returns the cached or newly fetched status data map, or null if unrelated.
  Future<Map<String, dynamic>?> enhanceProfile(String iccid) async {
    if (!AppSettings().enableProfileStatusEnhancer) {
      return null;
    }

    // 1. Check local cache
    final db = DatabaseService();
    final cached = await db.getCardStatus(iccid);

    if (cached != null) {
      final expiry = cached['expiry'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (expiry > now) {
        // Cache hit and valid
        try {
          return jsonDecode(cached['data'] as String) as Map<String, dynamic>;
        } catch (e) {
          _log.warning('Failed to decode cached status for $iccid: $e');
        }
      }
    }

    // 2. Route based on prefix
    if (iccid.startsWith('8985203')) {
      return await _fetchThreeHkStatus(iccid);
    }

    return null;
  }

  Future<Map<String, dynamic>?> _fetchThreeHkStatus(String iccid) async {
    try {
      // 3HK API uses 18 digits
      final choppedIccid = iccid.length > 18 ? iccid.substring(0, 18) : iccid;
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
          // 1. Normalize MSISDN
          if (json.containsKey('msisdn')) {
            String? msisdn = json['msisdn']?.toString();
            if (msisdn != null && msisdn.isNotEmpty) {
              // 3HK specific prefixing
              if (iccid.startsWith('8985203') && !msisdn.startsWith('+')) {
                msisdn = '+852$msisdn';
              }

              // Use a standard field 'normalizedMsisdn' or update 'msisdn'
              // User asked for "standardized field", let's use 'msisdn' but ensure it is standard.
              json['msisdn'] = msisdn;
            }
          }

          await _saveToCache(iccid, json);
          return json;
        }
      } else {
        _log.warning('3HK API failed for $iccid: ${response.statusCode}');
      }
    } catch (e) {
      _log.warning('Error fetching 3HK status for $iccid: $e');
    }
    return null;
  }

  Future<void> _saveToCache(String iccid, Map<String, dynamic> json) async {
    try {
      int expiryTime;
      final now = DateTime.now();

      // "expiry should be cached until (now + expiry) / 2 + 1 day"
      // User likely refers to "subsEndDate" in JSON as the source of "expiry".
      if (json.containsKey('subsEndDate')) {
        final subsEndDateStr = json['subsEndDate'];
        if (subsEndDateStr != null) {
          final subsEndDate = DateTime.parse(subsEndDateStr);
          // (now + expiry) / 2
          final midPoint = now.add(subsEndDate.difference(now) ~/ 2);
          // + 1 day
          expiryTime = midPoint
              .add(const Duration(days: 1))
              .millisecondsSinceEpoch;
        } else {
          // Fallback if null
          expiryTime = now.add(const Duration(days: 1)).millisecondsSinceEpoch;
        }
      } else {
        // Fallback default: 1 day
        expiryTime = now.add(const Duration(days: 1)).millisecondsSinceEpoch;
      }

      await DatabaseService().saveCardStatus(
        iccid,
        jsonEncode(json),
        expiryTime,
      );

      // Update in-memory cache so UI shows the data immediately
      CardStatusCache().invalidate(iccid);
      await CardStatusCache().getCardStatus(iccid);

      _log.info(
        'Saved enhanced status for $iccid (Expires: ${DateTime.fromMillisecondsSinceEpoch(expiryTime)})',
      );
    } catch (e) {
      _log.warning('Failed to save status cache for $iccid: $e');
    }
  }
}
