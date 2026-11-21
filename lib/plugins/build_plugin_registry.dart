// GENERATED FILE - DO NOT EDIT
// Run `dart run scripts/generate_plugin_registry.dart` to update.

import 'bee_sim_plugin.dart';
import 'esim_cc_plugin.dart';
import 'esim_gg_plugin.dart';
import 'estk_plugin.dart';
import 'gm_plugin.dart';
import 'linklan_plugin.dart';
import 'nekoko_stats_plugin.dart';
import 'thk_plugin.dart';
import 'ty_ble_plugin.dart';
import 'vowifi_plugin.dart';
import 'vowifi_sim_probe_plugin.dart';
import 'plugin_base.dart';
import 'session_plugin.dart';

typedef ProfilePluginFactory = ProfilePlugin Function();
typedef SessionPluginFactory = SessionPlugin Function();

class BuildPluginRegistry {
  BuildPluginRegistry._();

  static final Map<String, ProfilePluginFactory> _profileFactories =
      <String, ProfilePluginFactory>{
        'BeeSimPlugin': BeeSimPlugin.new,
        'EsimCcPlugin': EsimCcPlugin.new,
        'EsimGgPlugin': EsimGgPlugin.new,
        'EstkPlugin': EstkPlugin.new,
        'LinklanPlugin': LinklanPlugin.new,
        'NekokoStatsPlugin': NekokoStatsPlugin.new,
        'ThkPlugin': ThkPlugin.new,
        'TyBlePlugin': TyBlePlugin.new,
        'VowifiPlugin': VowifiPlugin.new,
        'VowifiSimProbePlugin': VowifiSimProbePlugin.new,
      };

  static final Map<String, SessionPluginFactory> _sessionFactories =
      <String, SessionPluginFactory>{
        'EstkPlugin': EstkPlugin.new,
        'GmPlugin': GmPlugin.new,
      };

  static List<ProfilePlugin> createPlugins() {
    return _profileFactories.values
        .map((factory) => factory())
        .toList(growable: false);
  }

  static List<SessionPlugin> createSessionPlugins() {
    return _sessionFactories.values
        .map((factory) => factory())
        .toList(growable: false);
  }
}
