import 'package:flutter/material.dart';
import '../services/tag_notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/styled_header_scaffold.dart';
import 'package:intl/intl.dart';
import '../utils/iccid_formatter.dart';
import '../l10n/app_localizations.dart';

class ScheduledNotificationsPage extends StatefulWidget {
  const ScheduledNotificationsPage({super.key});

  @override
  State<ScheduledNotificationsPage> createState() =>
      _ScheduledNotificationsPageState();
}

class _ScheduledNotificationsPageState
    extends State<ScheduledNotificationsPage> {
  bool _isLoading = true;
  List<ScheduledNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    // A failed load must not leave the spinner up for good.
    var list = _notifications;
    try {
      list = await TagNotificationService().getAllNotifications();
    } finally {
      if (mounted) {
        setState(() {
          _notifications = list;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StyledHeaderScaffold(
      title: AppLocalizations.of(context)!.tagReminders,
      subtitle: AppLocalizations.of(
        context,
      )!.activeReminders(_notifications.length),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notif = _notifications[index];
                return _buildNotificationTile(notif);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notification_important_outlined,
            size: 64,
            color: AppTheme.onSurfaceVerySubtle(context),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noScheduledReminders,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceSubtle(context),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              AppLocalizations.of(context)!.remindersAppearWhen,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.onSurfaceVerySubtle(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(ScheduledNotification notif) {
    final theme = Theme.of(context);
    final isExpired = notif.scheduledDate.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceSubtle(context)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isExpired ? Colors.red : theme.colorScheme.primary)
                .withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isExpired ? Icons.event_busy : Icons.event_available,
            size: 20,
            color: isExpired ? Colors.red : theme.colorScheme.primary,
          ),
        ),
        title: Text(
          notif.text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              "Date: ${DateFormat('yyyy-MM-dd').format(notif.scheduledDate)}",
              style: TextStyle(
                fontSize: 12,
                color: isExpired
                    ? Colors.red
                    : AppTheme.onSurfaceSubtle(context),
              ),
            ),
            Text(
              "${AppLocalizations.of(context)!.iccid}: ${IccidFormatter.forDisplay(notif.iccid)}",
              style: AppTheme.mono(
                TextStyle(
                  fontSize: 11,
                  color: AppTheme.onSurfaceVerySubtle(context),
                ),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
          onPressed: () async {
            await TagNotificationService().deleteNotification(
              notif.text,
              notif.scheduledDate,
            );
            _loadNotifications();
          },
        ),
      ),
    );
  }
}
