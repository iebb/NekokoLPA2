import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'plugin_base.dart';
import '../adapter/ble/ble_adapter.dart';
import '../adapter/euicc_adapter.dart';
import 'build_plugin_registry.dart';
import '../models/euicc_profile.dart';
import '../models/profile_card_bottom_data.dart';
import '../settings/app_settings.dart';

class PluginManager extends ChangeNotifier {
  static final Logger _log = Logger('PluginManager');
  static final PluginManager _instance = PluginManager._internal();
  factory PluginManager() => _instance;
  PluginManager._internal() {
    _registerPlugins();
  }

  final List<ProfilePlugin> _plugins = [];

  bool _isPluginAvailable(ProfilePlugin plugin) =>
      plugin.id != 'vowifi' || AppSettings().vowifiAvailable;

  Iterable<ProfilePlugin> get _availablePlugins =>
      _plugins.where(_isPluginAvailable);

  List<ProfilePlugin> get plugins => List.unmodifiable(_availablePlugins);

  void _registerPlugins() {
    _plugins
      ..clear()
      ..addAll(BuildPluginRegistry.createPlugins().where(_isPluginAvailable));
    for (final plugin in _plugins) {
      plugin.bleReaderKinds.forEach(BleAdapterType.register);
    }
  }

  List<PluginSettingsToggle> settingsToggles(BuildContext context) => [
    for (final plugin in _availablePlugins) ...plugin.settingsToggles(context),
  ];

  /// The first identity any plugin can read from a plain SIM, or null.
  Future<SimIdentity?> probeSim(Adapter adapter, Reader reader) async {
    for (final plugin in _availablePlugins) {
      final identity = await plugin.probeSim(adapter, reader);
      if (identity != null) return identity;
    }
    return null;
  }

  bool hasPlugin(String id) =>
      _availablePlugins.any((plugin) => plugin.id == id);

  List<AppTabSpec> get appTabs => _availablePlugins
      .where((plugin) {
        if (plugin.id == 'vowifi') {
          if (!AppSettings().vowifiEnabled) {
            return false;
          }
        }
        return true;
      })
      .map((plugin) => plugin.appTab)
      .whereType<AppTabSpec>()
      .toList(growable: false);

  Future<void> notifyProfilesLoaded(
    String eid,
    List<EuiccProfile> profiles,
  ) async {
    // Independent lookups: a slow or failing plugin must not hold up the rest.
    await Future.wait([
      for (final plugin in _availablePlugins)
        () async {
          try {
            await plugin.onProfilesLoaded(
              eid,
              profiles,
              onUpdate: notifyListeners,
            );
          } catch (e, stackTrace) {
            _log.warning(
              'Plugin ${plugin.id} failed while handling loaded profiles: $e',
              e,
              stackTrace,
            );
          }
        }(),
    ]);
    notifyListeners();
  }

  Future<void> notifyInstallationReported(
    InstallationReportContext report,
  ) async {
    for (final plugin in _availablePlugins) {
      try {
        await plugin.onInstallationReported(report);
      } catch (e, stackTrace) {
        _log.warning(
          'Plugin ${plugin.id} failed while handling installation report: $e',
          e,
          stackTrace,
        );
      }
    }
  }

  List<Widget> buildHeaders(BuildContext context, String? eid) {
    return _availablePlugins
        .map((p) => p.buildHeader(context, eid))
        .whereType<Widget>()
        .toList();
  }

  List<Widget> buildReaderActions(
    BuildContext context,
    ReaderActionContext actionContext,
  ) {
    return _availablePlugins
        .expand((plugin) => plugin.buildReaderActions(context, actionContext))
        .toList(growable: false);
  }

  List<Widget> buildProfileCardExtras(
    BuildContext context,
    EuiccProfile profile,
  ) {
    return _availablePlugins
        .where((p) => p.isMatch(profile))
        .map((p) => p.buildProfileCardExtra(context, profile))
        .whereType<Widget>()
        .toList();
  }

  ProfileCardBottomData? getMergedProfileCardBottomData(EuiccProfile profile) {
    ProfileCardBottomData? mergedData;

    final matchingPlugins = _availablePlugins.where((p) => p.isMatch(profile));

    for (final plugin in matchingPlugins) {
      final data = plugin.getProfileCardBottomData(profile);
      if (data != null && !data.isEmpty) {
        if (mergedData == null) {
          mergedData = data;
        } else {
          // Merge logic:
          // - Keep existing theme color (or maybe use the new one if the other was default?)
          // - Keep existing phone number if present, otherwise take new one
          // - Keep existing line expiry if present
          // - Keep existing balance
          // - Append packages
          // This is a simple merge strategy.
          mergedData = ProfileCardBottomData(
            themeColor: mergedData.themeColor, // Prefer first plugin's theme
            phoneNumber: mergedData.phoneNumber ?? data.phoneNumber,
            lineExpiry: mergedData.lineExpiry ?? data.lineExpiry,
            balance: mergedData.balance ?? data.balance,
            packages: [...mergedData.packages, ...data.packages],
          );
        }
      }
    }
    return mergedData;
  }

  List<PluginAction> getProfileActions(
    BuildContext context,
    EuiccProfile profile, {
    ReaderActionContext? actionContext,
  }) {
    return _availablePlugins
        .where((p) => p.isMatch(profile))
        .expand(
          (p) => p.getProfileActions(
            context,
            profile,
            actionContext: actionContext,
          ),
        )
        .toList();
  }

  List<PluginAction> getEidActions(
    BuildContext context,
    String? eid, {
    String? aid,
  }) {
    return _availablePlugins
        .expand((p) => p.getEidActions(context, eid, aid: aid))
        .toList();
  }

  Map<String, WidgetBuilder> get allRoutes {
    final routes = <String, WidgetBuilder>{};
    for (final plugin in _availablePlugins) {
      routes.addAll(plugin.routes);
    }
    return routes;
  }
}
