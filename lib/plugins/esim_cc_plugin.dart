import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'plugin_base.dart';
import '../models/euicc_profile.dart';
import '../theme/app_theme.dart';

class EsimCcPlugin extends ProfilePlugin {
  @override
  String get id => 'esim_cc';

  @override
  String get name => 'eSIM.cc';

  @override
  bool isMatch(EuiccProfile profile) {
    return profile.iccid.startsWith('8985223');
  }

  @override
  Widget? buildProfileCardExtra(BuildContext context, EuiccProfile profile) {
    if (!isMatch(profile)) return null;

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: InkWell(
        onTap: () => _launchUrl('https://www.esim.cc/card-bonus'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: AppTheme.badgeDecoration(context, Colors.orange),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.card_giftcard, size: 14, color: Colors.orange),
              const SizedBox(width: 4),
              Text(
                AppLocalizations.of(context)!.pluginEsimCcRewards,
                style: AppTheme.badgeTextStyle(context, Colors.orange),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  List<PluginAction> getProfileActions(
    BuildContext context,
    EuiccProfile profile, {
    ReaderActionContext? actionContext,
  }) {
    if (!isMatch(profile)) return [];

    return [
      PluginAction(
        label: AppLocalizations.of(context)!.pluginEsimCcPortal,
        icon: Icons.language,
        onTap: () => _launchUrl('https://www.esim.cc/'),
      ),
    ];
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
