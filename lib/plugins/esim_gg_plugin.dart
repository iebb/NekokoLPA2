import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'plugin_base.dart';
import '../models/euicc_profile.dart';
import '../services/card_status_cache.dart';
import '../services/database_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import 'package:dlibphonenumber/dlibphonenumber.dart';
import '../models/profile_card_bottom_data.dart';

class EsimGgPlugin extends ProfilePlugin {
  static final Logger _log = Logger('EsimGgPlugin');

  @override
  String get id => 'esim_gg';

  @override
  String get name => 'eSIM.gg';

  @override
  bool isMatch(EuiccProfile profile) {
    return profile.iccid.startsWith('893720401');
  }

  @override
  Future<void> onProfilesLoaded(
    String eid,
    List<EuiccProfile> profiles, {
    VoidCallback? onUpdate,
  }) async {
    final matched = profiles.where((p) => isMatch(p)).toList();
    if (matched.isEmpty) return;

    // Check which ones need refresh
    final toRefresh = <String>[];
    for (final p in matched) {
      final cacheKey = '${id}_${p.iccid}';
      final cached = await CardStatusCache().getCardStatus(cacheKey);
      if (cached == null) {
        toRefresh.add(p.iccid);
      }
    }

    if (toRefresh.isNotEmpty) {
      await _fetchStatusBulk(toRefresh);
      onUpdate?.call();
    }
  }

  Future<void> _fetchStatusBulk(List<String> iccids) async {
    try {
      // Map stripped ICCIDs to original ones
      final idMap = {
        for (var id in iccids)
          (id.toUpperCase().endsWith('F')
                  ? id.substring(0, id.length - 1)
                  : id):
              id,
      };

      final response = await http
          .post(
            Uri.parse('https://api.nekoko.tel/nekokolpa/by_iccid'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'iccids': idMap.keys.toList()}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded['results'];
        if (list is List) {
          for (final item in list) {
            final receivedId = item['iccid']?.toString();
            if (receivedId != null) {
              // Try to find original ICCID (with F) from the received one (without F)
              final originalId = idMap[receivedId] ?? receivedId;
              final cacheKey = '${id}_$originalId';

              // Merge with existing data to keep things like phone number indefinitely
              final existing = await CardStatusCache().getCardStatus(cacheKey);
              final merged = Map<String, dynamic>.from({...?existing, ...item});

              await DatabaseService().saveCardStatus(
                cacheKey,
                jsonEncode(merged),
                DateTime.now()
                    .add(const Duration(hours: 12))
                    .millisecondsSinceEpoch,
              );
              CardStatusCache().updateCache(cacheKey, merged);
            }
          }
        }
      }
    } catch (e) {
      _log.warning('eSIM.gg bulk fetch failed: $e');
    }
  }

  @override
  Map<String, WidgetBuilder> get routes => {
    '/plugin/esim_gg': (context) => const EsimGgPortalPage(),
  };

  @override
  Widget? buildProfileCardExtra(BuildContext context, EuiccProfile profile) {
    if (!isMatch(profile)) return null;

    final cacheKey = '${id}_${profile.iccid}';
    final data = CardStatusCache().getCardStatusSync(cacheKey);
    if (data == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Row(
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 12,
              color: Colors.blue[700],
            ),
            const SizedBox(width: 4),
            Text(
              AppLocalizations.of(context)!.pluginEsimGgProfile,
              style: AppTheme.badgeTextStyle(context, Colors.blue[700]!),
            ),
          ],
        ),
      );
    }

    return null;
  }

  @override
  ProfileCardBottomData? getProfileCardBottomData(EuiccProfile profile) {
    if (!isMatch(profile)) return null;

    final cacheKey = '${id}_${profile.iccid}';
    final data = CardStatusCache().getCardStatusSync(cacheKey);
    if (data == null) return null;

    final rawNumber = data['number'] as String?;
    String? number = rawNumber;
    if (rawNumber != null && rawNumber.isNotEmpty) {
      try {
        final util = PhoneNumberUtil.instance;
        final parsed = util.parse(
          rawNumber.startsWith('+') ? rawNumber : '+$rawNumber',
          null,
        );
        number = util.format(parsed, PhoneNumberFormat.international);
      } catch (_) {
        number = (rawNumber.startsWith('372') || rawNumber.startsWith('+372'))
            ? (rawNumber.startsWith('+') ? rawNumber : '+$rawNumber')
            : rawNumber;
      }
    }

    final balance = data['balance'];
    final lineExpiry = data['expire_date'] as String?;

    final packageName = data['package_name'] as String?;
    final remainingRaw = data['remaining_data'];
    final totalRaw = data['total_data'];
    final packageExpiry = data['package_expiry'] as String? ?? lineExpiry;

    final hasPackage =
        packageName != null && remainingRaw != null && totalRaw != null;

    return ProfileCardBottomData(
      themeColor: Colors.blue,
      phoneNumber: number,
      lineExpiry: null, // User requested no line expiry for eSIM.gg
      balance: (balance is num)
          ? "${balance.toDouble().toStringAsFixed(2)} €"
          : null,
      packages: hasPackage
          ? <ProfilePackage>[
              ProfilePackage(
                name: packageName,
                totalBytes: (totalRaw is num) ? totalRaw.toDouble() : 0.0,
                usedBytes: (totalRaw is num && remainingRaw is num)
                    ? (totalRaw.toDouble() - remainingRaw.toDouble())
                    : 0.0,
                expiry: packageExpiry,
              ),
            ]
          : <ProfilePackage>[],
    );
  }
}

class EsimGgPortalPage extends StatelessWidget {
  const EsimGgPortalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.pluginEsimGgPortal),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.pluginEsimGgWelcome,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _launchUrl('https://esim.gg/'),
              child: Text(AppLocalizations.of(context)!.pluginVisitWebsite),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
