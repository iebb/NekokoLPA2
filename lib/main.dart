import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'l10n/app_localizations.dart';

import 'config.dart';
import 'theme/app_theme.dart';
import 'settings/app_settings.dart';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';
import 'services/db_init_native.dart'
    if (dart.library.js_interop) 'services/db_init_web.dart';
import 'services/log_buffer.dart';
import 'services/local_notification_service.dart';
import 'services/deep_link_service.dart';
import 'widgets/profile_installation_dialog.dart';
import 'plugins/plugin_manager.dart';

import 'dart:convert';
import 'pages/reminder_details_page.dart';
import 'pages/main_tab_screen.dart';
import 'vowifi/inbox_page.dart';
import 'pages/vowifi_sms_page.dart';

import 'utils/migration_helper.dart';
import 'utils/locale_utils.dart';

import './src/rust/frb_generated.dart';
import 'utils/platform_adapter.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

const String _sentryDsn = String.fromEnvironment('SENTRY_DSN');
const String _sentryTracesSampleRateValue = String.fromEnvironment(
  'SENTRY_TRACES_SAMPLE_RATE',
  defaultValue: '0.0',
);
final double _sentryTracesSampleRate =
    double.tryParse(_sentryTracesSampleRateValue) ?? 0.0;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initRust();

  final packageInfo = await PackageInfo.fromPlatform();
  final version = packageInfo.version;
  final versionParts = version.split('.');
  final isCandidate = versionParts.length >= 3 && versionParts[2] != '0';

  if (isCandidate && _sentryDsn.isNotEmpty) {
    await SentryFlutter.init((options) {
      options.dsn = _sentryDsn;
      options.tracesSampleRate = _sentryTracesSampleRate;
    }, appRunner: () => _runMain());
  } else {
    _runMain();
  }
}

/// Load the Rust library, on the platform that has it.
///
/// The library is only behind the QRTR reader, which is Android's: every other
/// platform starts without it, so a build that carries no native library for
/// the platform it is running on still runs.
Future<void> _initRust() async {
  if (!PlatformX.isAndroid) return;
  await RustLib.init();
}

void _runMain() async {
  // Initialize synchronous services up-front so logs from later async work are captured.
  Logger.root.level = Level.ALL;
  LogBuffer().init(); // Start buffering logs
  LogBuffer().startFileLogging(); // Keep this run's full log on disk
  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      print(
        '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}',
      );
    }
  });
  // DB must be ready before AppSettings (which queries DatabaseService).
  await initDb();

  // Run the two heavy async inits in parallel — they are independent.
  await Future.wait([AppSettings().init(), LocalNotificationService().init()]);

  // Plugin availability depends on the resolved build flavor.
  PluginManager();

  // Cheap follow-ups — no need to block startup further.
  DeepLinkService().init();
  MigrationHelper.performMigration();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static final Logger _log = Logger('MyApp');
  @override
  void initState() {
    super.initState();
    // Listen for notification clicks
    LocalNotificationService().payloadStream.listen((payload) {
      if (payload != null) {
        _handleNotificationPayload(payload);
      }
    });

    // Listen for foreground notifications to show in-app
    LocalNotificationService().foregroundNotificationStream.listen((
      notification,
    ) {
      if (scaffoldMessengerKey.currentState != null) {
        scaffoldMessengerKey.currentState!.clearSnackBars();
        scaffoldMessengerKey.currentState!.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            backgroundColor: Theme.of(
              navigatorKey.currentContext!,
            ).colorScheme.surface,
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      navigatorKey.currentContext!,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: Theme.of(
                      navigatorKey.currentContext!,
                    ).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (notification.title != null)
                        Text(
                          notification.title!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              navigatorKey.currentContext!,
                            ).colorScheme.onSurface,
                          ),
                        ),
                      if (notification.body != null)
                        Text(
                          notification.body!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.onSurfaceSubtle(
                              navigatorKey.currentContext!,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            action: notification.payload != null
                ? SnackBarAction(
                    label: "VIEW",
                    onPressed: () {
                      // Reuse the notification tap logic
                      _handleNotificationPayload(notification.payload!);
                    },
                  )
                : null,
          ),
        );
      }
    });

    // Listen for Pending LPAs
    DeepLinkService().pendingLpa.addListener(_onPendingLpaChanged);
    // Check initial state
    _onPendingLpaChanged();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final payload = await LocalNotificationService().getLaunchPayload();
        if (mounted && payload != null) _handleNotificationPayload(payload);
      } catch (_) {
        _log.warning('Could not read the notification launch action');
      }
    });
  }

  @override
  void dispose() {
    DeepLinkService().pendingLpa.removeListener(_onPendingLpaChanged);
    super.dispose();
  }

  void _onPendingLpaChanged() async {
    final code = DeepLinkService().pendingLpa.value;
    if (code != null && navigatorKey.currentState != null) {
      // Show dialog if not already showing?
      // Simple debounce/check: ensure we are at top context or check if we just showed it.
      // But for now, just push.

      // Wait a bit for navigation stability if startup
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      if (navigatorKey.currentState?.context == null) return;

      showDialog(
        context: navigatorKey.currentState!.context,
        barrierDismissible: false, // User must choose
        builder: (context) => ProfileInstallationDialog(lpaCode: code),
      );
    }
  }

  void _handleNotificationPayload(String payload) {
    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      if (data['type'] == 'vowifi_sms') {
        if (PlatformX.isIOS) {
          final lineKey = data['lineKey'];
          if (lineKey is! String || lineKey.isEmpty) return;
          navigatorKey.currentState?.push(
            MaterialPageRoute<void>(
              builder: (_) => VoWifiInboxPage(lineKey: lineKey),
            ),
          );
          return;
        } else if (PlatformX.isDesktop && AppSettings().vowifiEnabled) {
          navigatorKey.currentState?.push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  VowifiSmsPage(initialSessionId: data['lineKey'] as String?),
            ),
          );
          return;
        }
      }
      final String? iccid = data['iccid'];
      final String? eid = data['eid'];

      if (iccid != null && navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) =>
                ReminderDetailsPage(iccid: iccid, eid: eid ?? ''),
          ),
        );
      }
    } catch (e) {
      _log.warning("Error parsing notification payload: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return const _AppSettingsScope();
  }
}

/// Rebuilds when AppSettings fields that affect MaterialApp
/// (themeMode, themeType, locale) change.
class _AppSettingsScope extends StatefulWidget {
  const _AppSettingsScope();

  @override
  State<_AppSettingsScope> createState() => _AppSettingsScopeState();
}

class _AppSettingsScopeState extends State<_AppSettingsScope> {
  late ThemeMode _themeMode;
  late AppThemeType _themeType;
  String? _locale;

  @override
  void initState() {
    super.initState();
    final s = AppSettings();
    _themeMode = s.themeMode;
    _themeType = s.themeType;
    _locale = s.locale;
    s.addListener(_onChange);
  }

  @override
  void dispose() {
    AppSettings().removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    final s = AppSettings();
    if (s.themeMode != _themeMode ||
        s.themeType != _themeType ||
        s.locale != _locale) {
      setState(() {
        _themeMode = s.themeMode;
        _themeType = s.themeType;
        _locale = s.locale;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedLocale = localeFromPreference(_locale);
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: AppConfig.appName,
      theme: AppTheme.theme(false),
      darkTheme: AppTheme.theme(true),
      themeMode: _themeMode,
      locale: resolvedLocale,
      home: const MainTabScreen(),
      routes: PluginManager().allRoutes,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveSupportedLocale,
    );
  }
}
