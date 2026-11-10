import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/l10n/app_localizations.dart';
import 'package:nlpa2/services/error_report_service.dart';
import 'package:nlpa2/utils/error_codes.dart';
import 'package:nlpa2/widgets/profiles_screen/error_state.dart';

Future<void> _pumpError(WidgetTester tester, Object error) => tester.pumpWidget(
  MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: ErrorState(error: error, onRetry: () {}),
    ),
  ),
);

void main() {
  final omapiLock = PlatformException(
    code: 'OMAPI_SESSION_CORRUPTED',
    message: 'SIM/eSIM channel became invalid.',
    details: {'reason': 'Persisted OMAPI poison state is incomplete'},
  );
  // Only the 9eSIM build, given a DSN, can send; no other build shows the
  // button. Run with --dart-define=ESIM9_BUILD=true and SENTRY_DSN to see it.
  final reportable = ErrorReportService.isAvailable
      ? findsOneWidget
      : findsNothing;

  testWidgets('offers a report for an OMAPI lock', (tester) async {
    await _pumpError(tester, omapiLock);
    expect(find.text('Send report'), reportable);
  });

  testWidgets('offers a report for a wrapped OMAPI lock', (tester) async {
    await _pumpError(
      tester,
      AppException(
        AppErrorCode.ERROR_OMAPI_SESSION_CORRUPTED,
        message: 'SIM/eSIM channel became invalid.',
        originalError: omapiLock,
      ),
    );
    expect(find.text('Send report'), reportable);
  });

  testWidgets('asks before sending', (tester) async {
    if (!ErrorReportService.isAvailable) return;
    await _pumpError(tester, omapiLock);
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();
    expect(find.text('Send error report?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Send error report?'), findsNothing);
  });

  testWidgets('does not offer a report for other errors', (tester) async {
    await _pumpError(tester, Exception('reader went away'));
    expect(find.text('Send report'), findsNothing);
  });
}
