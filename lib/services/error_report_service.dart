import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../utils/error_codes.dart';
import 'log_buffer.dart';

/// Sends an error the user chose to report to Sentry, for manual review.
///
/// Candidate builds already run Sentry. Releases (x.y.0) start without it, so
/// the first report starts it with crash and ANR capture off, and every event
/// that is not a manual report is dropped: pressing the button sends that
/// report and nothing else.
class ErrorReportService {
  static const String _dsn = String.fromEnvironment('SENTRY_DSN');
  static const String _manualReportTag = 'manual_report';
  static final Logger _log = Logger('ErrorReportService');

  static bool get isAvailable => _dsn.isNotEmpty;

  /// Returns the Sentry event id, or null when nothing was sent.
  static Future<SentryId?> report(Object error, {required String kind}) async {
    if (!isAvailable) return null;
    try {
      if (!Sentry.isEnabled) await _startForManualReports();

      final platformError = _platformException(error);
      final log = LogBuffer().logs.map(_formatRecord).join('\n');
      final id = await Sentry.captureException(
        error,
        withScope: (scope) async {
          await scope.setTag(_manualReportTag, 'true');
          await scope.setTag('report_kind', kind);
          if (platformError != null) {
            await scope.setTag('platform_error_code', platformError.code);
            await scope.setContexts('platform_error', {
              'code': platformError.code,
              'message': platformError.message,
              'details': platformError.details?.toString(),
            });
          }
          scope.addAttachment(
            SentryAttachment.fromIntList(
              utf8.encode(log),
              'app.log',
              contentType: 'text/plain',
            ),
          );
        },
      );
      if (id == const SentryId.empty()) return null;
      _log.info('Sent $kind report to Sentry: $id');
      return id;
    } catch (e) {
      _log.warning('Unable to send $kind report: $e');
      return null;
    }
  }

  static Future<void> _startForManualReports() => SentryFlutter.init((options) {
    options.dsn = _dsn;
    options.enableNativeCrashHandling = false;
    options.anrEnabled = false;
    options.enableAutoSessionTracking = false;
    options.beforeSend = (event, hint) =>
        event.tags?[_manualReportTag] == 'true' ? event : null;
  });

  static PlatformException? _platformException(Object error) {
    if (error is PlatformException) return error;
    if (error is AppException && error.originalError is Object) {
      return _platformException(error.originalError as Object);
    }
    return null;
  }

  static String _formatRecord(LogRecord record) {
    final line =
        '${record.time.toIso8601String()} ${record.level.name} '
        '${record.loggerName}: ${record.message}';
    return record.error == null ? line : '$line\n  ${record.error}';
  }
}
