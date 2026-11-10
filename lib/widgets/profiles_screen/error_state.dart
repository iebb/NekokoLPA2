import 'package:flutter/material.dart';
import '../../adapter/omapi/omapi_safety.dart';
import '../../l10n/app_localizations.dart';
import '../../services/error_report_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/apdu_exception.dart';
import '../../utils/error_codes.dart';

/// Base widget for displaying state messages in the profiles screen.
class ColumnStateMessage extends StatelessWidget {
  final Widget icon;
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Color? iconContainerColor;

  const ColumnStateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actions,
    this.iconContainerColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color:
                    iconContainerColor ??
                    theme.colorScheme.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: icon,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.onSurfaceSubtle(context),
                  height: 1.4,
                ),
              ),
            ],
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: 32),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: actions!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Whether an error means the card needs to be physically re-seated.
///
/// Covers both the typed exception and the raw status words, because the same
/// condition arrives as a [ConditionOfUseNotSatisfiedException] from one path
/// and as a wrapped message from another.
bool _needsReplug(Object error) {
  if (error is ConditionOfUseNotSatisfiedException) return true;
  if (error is AppException &&
      error.code == AppErrorCode.ERROR_CONDITION_OF_USE_NOT_SATISFIED) {
    return true;
  }
  final text = error.toString();
  return text.contains('SW=6985') ||
      text.contains('SW=6999') ||
      text.contains('temporarily unavailable');
}

/// Generic error state widget that shows different messages based on error type
class ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const ErrorState({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Determine error type and customize display
    String title;
    String? subtitle;
    IconData icon;
    Color iconColor;

    if (_needsReplug(error)) {
      // 6985/6999 from the ISD-R mean the eUICC will not hand over its
      // management applet: it is mid profile state change, or serving a
      // fallback because nothing usable is enabled. Nothing reachable over the
      // reader clears either, so name the one action that does.
      title = l10n.cardNeedsReplugTitle;
      subtitle = l10n.cardNeedsReplugMessage;
      icon = Icons.sim_card_download_rounded;
      iconColor = Colors.orange;
    } else if (error is AppException) {
      final appError = error as AppException;

      switch (appError.code) {
        case AppErrorCode.ERROR_CARD_NOT_PRESENT:
          // This should be handled by NoCardDetectedState, but just in case
          title = l10n.noCardDetected;
          subtitle = l10n.noCardDetectedSubtitle;
          icon = Icons.sim_card_alert_outlined;
          iconColor = AppTheme.onSurfaceSubtle(context);
          break;

        case AppErrorCode.ERROR_BLUETOOTH_TIMEOUT:
          title = l10n.bluetoothConnectionFailed;
          subtitle = l10n.errorBluetoothTimeout;
          icon = Icons.bluetooth_disabled_rounded;
          iconColor = theme.colorScheme.error;
          break;

        case AppErrorCode.ERROR_OMAPI_SECURITYEXCEPTION:
        case AppErrorCode.ERROR_OMAPI_PERMISSION_DENIED:
          title = l10n.accessDenied;
          subtitle = l10n.errorOmapiSecurity;
          icon = Icons.lock_person_outlined;
          iconColor = Colors.orange;
          break;

        case AppErrorCode.ERROR_APPLICATION_NOT_FOUND:
          title = l10n.cardUnsupported;
          subtitle = l10n.errorApplicationNotFound;
          icon = Icons.sd_card_alert_rounded;
          iconColor = theme.colorScheme.error;
          break;

        case AppErrorCode.ERROR_CONDITION_OF_USE_NOT_SATISFIED:
          title = l10n.cardRefreshingTitle;
          subtitle = l10n.cardStuckRefreshingMessage;
          icon = Icons.sync_problem_rounded;
          iconColor = Colors.orange;
          break;

        default:
          // Generic error with custom message if available
          title = l10n.failed;
          subtitle = appError.message ?? error.toString();
          icon = Icons.error_outline;
          iconColor = theme.colorScheme.error;
      }
    } else {
      // Generic non-AppException error
      title = l10n.failed;
      subtitle = error.toString();
      icon = Icons.error_outline;
      iconColor = theme.colorScheme.error;
    }

    return ColumnStateMessage(
      icon: Icon(icon, size: 64, color: iconColor),
      iconContainerColor: iconColor.withValues(alpha: 0.1),
      title: title,
      subtitle: subtitle,
      actions: [
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(l10n.retry),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
        if (ErrorReportService.isAvailable &&
            isOmapiSessionCorruptedError(error))
          _SendReportButton(error: error, kind: 'omapi_session_corrupted'),
      ],
    );
  }
}

/// Sends [error] to Sentry for manual review, after the user confirms.
class _SendReportButton extends StatefulWidget {
  final Object error;
  final String kind;

  const _SendReportButton({required this.error, required this.kind});

  @override
  State<_SendReportButton> createState() => _SendReportButtonState();
}

class _SendReportButtonState extends State<_SendReportButton> {
  bool _sending = false;

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.sendErrorReportTitle),
        content: Text(l10n.sendErrorReportMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.sendErrorReport),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _sending = true);
    final id = await ErrorReportService.report(widget.error, kind: widget.kind);
    if (!mounted) return;
    setState(() => _sending = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          id == null
              ? l10n.errorReportFailed
              : l10n.errorReportSent(id.toString().substring(0, 8)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OutlinedButton.icon(
      onPressed: _sending ? null : _send,
      icon: _sending
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.bug_report_outlined),
      label: Text(l10n.sendErrorReport),
    );
  }
}
