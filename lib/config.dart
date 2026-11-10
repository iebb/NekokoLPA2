import 'utils/platform_adapter.dart';

bool get kIsPrivileged =>
    const bool.fromEnvironment('PRIVILEGED_BUILD', defaultValue: false) &&
    PlatformX.isAndroid;

bool get kIsEsim9 =>
    const bool.fromEnvironment('ESIM9_BUILD', defaultValue: false);

/// Sentry is part of the 9eSIM build only. Both are compile-time constants, so
/// every other build drops the reporting code and ignores a DSN it is given.
const String kSentryDsn = bool.fromEnvironment('ESIM9_BUILD')
    ? String.fromEnvironment('SENTRY_DSN')
    : '';
const bool kSentryEnabled = kSentryDsn != '';

class AppConfig {
  static const String appName = 'NekokoLPA 2';
}
