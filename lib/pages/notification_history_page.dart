import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/profile_metadata_service.dart';
import '../models/asn1/rsp_definitions.g.dart';
import '../utils/iccid_formatter.dart';
import '../theme/app_theme.dart';
import '../widgets/common/simple_dialog_container.dart';
import '../widgets/styled_header_scaffold.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../logic/profile_manager.dart';

class NotificationHistoryPage extends StatefulWidget {
  const NotificationHistoryPage({super.key});

  @override
  State<NotificationHistoryPage> createState() =>
      _NotificationHistoryPageState();
}

class _NotificationHistoryPageState extends State<NotificationHistoryPage> {
  List<NotificationRecord> _records = [];
  String _searchQuery = "";
  final Map<String, Future<ProfileMetadata?>> _profileMetadataCache = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await DatabaseService().getAllNotifications();
    setState(() {
      _records = data;
    });
  }

  List<NotificationRecord> get _filteredRecords {
    if (_searchQuery.isEmpty) return _records;
    final query = _searchQuery.toLowerCase();
    return _records.where((r) {
      final cleanedIccid = IccidFormatter.forDisplay(r.iccid);
      return r.iccid.toLowerCase().contains(query) ||
          cleanedIccid.toLowerCase().contains(query) ||
          r.eid.toLowerCase().contains(query) ||
          (r.responseContent?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Future<ProfileMetadata?> _fetchProfileMetadata(String iccid) {
    return _profileMetadataCache.putIfAbsent(iccid, () async {
      try {
        final service = await ProfileMetadataService.getInstance();
        return await service.getProfile(iccid);
      } catch (_) {
        return null;
      }
    });
  }

  Future<void> _delete(NotificationRecord record) async {
    await DatabaseService().deleteNotification(
      record.eid,
      record.seqNumber,
      record.iccid,
    );
    _loadData();
  }

  Future<void> _resend(NotificationRecord record) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final bytes = base64Decode(record.content);
      final notif = PendingNotification.decode(bytes);
      final metadata = ProfileManager.extractMetadata(notif);
      final address =
          record.notificationServer ?? metadata?.notificationAddress;

      if (address == null || address.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.noAddressInNotification,
              ),
            ),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.resending)),
        );
      }

      final result = await NotificationService().sendNotificationRaw(
        notif,
        address,
      );

      if (result.success) {
        final successContent = record.content.isNotEmpty
            ? record.content
            : l10n.resentSuccessfully;
        await DatabaseService().updateNotificationStatus(
          record.eid,
          record.seqNumber,
          record.iccid,
          1,
          responseCode: result.statusCode == 0 ? null : result.statusCode,
          responseContent: successContent,
        );
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.sentSuccessfully)));
        }
      } else {
        final failedContent = result.body.isNotEmpty
            ? result.body
            : l10n.resendFailed;
        await DatabaseService().updateNotificationStatus(
          record.eid,
          record.seqNumber,
          record.iccid,
          2,
          responseCode: result.statusCode == 0 ? null : result.statusCode,
          responseContent: failedContent,
        );
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.sendFailed),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorWithDetails(e.toString()),
            ),
          ),
        );
      }
    }
  }

  void _showDetails(NotificationRecord record) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: AppLocalizations.of(context)!.dismiss,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        final theme = Theme.of(context);
        return SimpleDialogContainer(
          title: AppLocalizations.of(context)!.notificationDetails,
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow(
                    context,
                    AppLocalizations.of(context)!.type,
                    (record.notificationType ??
                            AppLocalizations.of(context)!.unknown)
                        .toUpperCase(),
                  ),
                  _detailRow(
                    context,
                    AppLocalizations.of(context)!.eid,
                    record.eid,
                  ),
                  _detailRow(
                    context,
                    AppLocalizations.of(context)!.iccid,
                    IccidFormatter.forDisplay(record.iccid),
                  ),
                  _detailRow(
                    context,
                    AppLocalizations.of(context)!.seq,
                    record.seqNumber.toString(),
                  ),
                  _detailRow(
                    context,
                    AppLocalizations.of(context)!.date,
                    DateFormat("yyyy-MM-dd HH:mm:ss").format(
                      DateTime.fromMillisecondsSinceEpoch(record.timestamp),
                    ),
                  ),
                  _detailRow(
                    context,
                    AppLocalizations.of(context)!.status,
                    _statusStr(context, record.status),
                  ),
                  if (record.responseCode != null)
                    _detailRow(
                      context,
                      AppLocalizations.of(context)!.responseCode,
                      record.responseCode.toString(),
                    ),
                  if (record.responseContent != null &&
                      record.responseContent!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceSubtle(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.responseBody,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onSurfaceSubtle(context),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              record.responseContent!,
                              style: AppTheme.mono(
                                TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _exportAsCurl(NotificationRecord record) {
    try {
      final bytes = base64Decode(record.content);
      final notif = PendingNotification.decode(bytes);
      final metadata = ProfileManager.extractMetadata(notif);
      final address =
          record.notificationServer ?? metadata?.notificationAddress;

      if (address == null || address.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.noAddressToExport),
          ),
        );
        return;
      }

      final url = 'https://$address/gsma/rsp2/es9plus/handleNotification';
      final base64Payload = base64Encode(notif.encode());

      final curl =
          'curl -X POST $url \\\n'
          '  -H "User-Agent: gsma-rsp-lpad" \\\n'
          '  -H "X-Admin-Protocol: gsma/rsp/v2.2.0" \\\n'
          '  -H "Content-Type: application/json" \\\n'
          '  -d \'{"pendingNotification": "$base64Payload"}\'';

      Clipboard.setData(ClipboardData(text: curl));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.copiedCurl),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.exportFailed(e.toString()),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _statusStr(BuildContext context, int s) {
    final l10n = AppLocalizations.of(context)!;
    if (s == 1) return l10n.sent;
    if (s == 2) return l10n.failed;
    return l10n.pending;
  }

  Widget _buildStatusIndicator(
    BuildContext context,
    int status,
    Color statusColor,
  ) {
    if (status == 1) {
      return Tooltip(
        message: AppLocalizations.of(context)!.sent,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blue.withValues(alpha: 0.28)),
          ),
          child: Icon(Icons.send_rounded, size: 15, color: Colors.blue[500]),
        ),
      );
    }

    return Text(
      _statusStr(context, status),
      style: TextStyle(
        color: statusColor,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.onSurfaceSubtle(context),
            ),
          ),
          SelectableText(
            value,
            style: AppTheme.mono(
              TextStyle(fontSize: 14, color: AppTheme.onSurface(context)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StyledHeaderScaffold(
      title: AppLocalizations.of(context)!.notificationHistory,
      subtitle: _records.isNotEmpty
          ? AppLocalizations.of(context)!.records(_records.length)
          : null,
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              onChanged: (v) => setState(
                () => _searchQuery = v,
              ), // Reverted to original onChanged logic
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchByIccid,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppTheme.onSurfaceSubtle(context),
                ),
                filled: true,
                fillColor: AppTheme.surfaceSubtle(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.dividerColor, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),

          Expanded(
            child:
                _filteredRecords
                    .isEmpty // Changed _history.isEmpty to _filteredRecords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 80,
                          color: AppTheme.onSurfaceVerySubtle(context),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.noHistoryAvailable,
                          style: TextStyle(
                            color: AppTheme.onSurfaceSubtle(context),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: _filteredRecords.length,
                    itemBuilder: (context, index) {
                      final theme = Theme.of(context);
                      final isDark = theme.brightness == Brightness.dark;
                      final r = _filteredRecords[index];
                      final payloadLength = base64Decode(r.content).length;
                      final cleanedIccid = IccidFormatter.forDisplay(r.iccid);

                      // Get notification type color and icon
                      Color typeColor = Colors.grey;
                      IconData typeIcon = Icons.notifications;
                      if (r.notificationType == 'install') {
                        typeColor = Colors.blue;
                        typeIcon = Icons.download;
                      } else if (r.notificationType == 'delete') {
                        typeColor = Colors.red;
                        typeIcon = Icons.delete;
                      } else if (r.notificationType == 'enable') {
                        typeColor = Colors.green;
                        typeIcon = Icons.check_circle;
                      } else if (r.notificationType == 'disable') {
                        typeColor = Colors.orange;
                        typeIcon = Icons.cancel;
                      } else if (r.notificationType == 'rpm enable') {
                        typeColor = Colors.purple;
                        typeIcon = Icons.cloud_upload_outlined;
                      } else if (r.notificationType == 'rpm disable') {
                        typeColor = Colors.deepOrange;
                        typeIcon = Icons.cloud_off_outlined;
                      } else if (r.notificationType == 'rpm delete') {
                        typeColor = Colors.pink;
                        typeIcon = Icons.cloud_done_outlined;
                      } else if (r.notificationType == 'load rpm') {
                        typeColor = Colors.teal;
                        typeIcon = Icons.inventory_2_outlined;
                      }

                      final statusColor = r.status == 1
                          ? Colors.green
                          : r.status == 2
                          ? Colors.red
                          : Colors.orange;

                      return FutureBuilder<ProfileMetadata?>(
                        future: _fetchProfileMetadata(r.iccid),
                        builder: (context, snapshot) {
                          final profileMeta = snapshot.data;
                          final fallbackName = cleanedIccid;
                          final profileName =
                              profileMeta?.displayName ?? fallbackName;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.surfaceSubtle(context),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.3 : 0.04,
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _showDetails(r),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: AppTheme.surfaceSubtle(
                                                context,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              typeIcon,
                                              color: typeColor,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  profileName,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 15,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface,
                                                    letterSpacing: -0.3,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.credit_card_rounded,
                                                      size: 12,
                                                      color:
                                                          AppTheme.onSurfaceVerySubtle(
                                                            context,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        cleanedIccid,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              AppTheme.onSurfaceSubtle(
                                                                context,
                                                              ),
                                                          letterSpacing: 0.2,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (r.notificationServer !=
                                                        null &&
                                                    r
                                                        .notificationServer!
                                                        .isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.cloud_outlined,
                                                        size: 12,
                                                        color:
                                                            AppTheme.onSurfaceVerySubtle(
                                                              context,
                                                            ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          r.notificationServer!,
                                                          style: TextStyle(
                                                            color:
                                                                AppTheme.onSurfaceSubtle(
                                                                  context,
                                                                ),
                                                            fontSize: 11,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              if (r.notificationType !=
                                                  null) ...[
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: typeColor.withValues(
                                                      alpha: 0.12,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color: typeColor
                                                          .withValues(
                                                            alpha: 0.25,
                                                          ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        typeIcon,
                                                        size: 12,
                                                        color: typeColor,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        r.notificationType!
                                                            .toUpperCase(),
                                                        style: TextStyle(
                                                          color: typeColor,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                              ],
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  _buildStatusIndicator(
                                                    context,
                                                    r.status,
                                                    statusColor,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  PopupMenuButton<String>(
                                                    padding: EdgeInsets.zero,
                                                    icon: Material(
                                                      color:
                                                          AppTheme.surfaceSubtle(
                                                            context,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      child: InkWell(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                8,
                                                              ),
                                                          child: Icon(
                                                            Icons
                                                                .more_horiz_rounded,
                                                            color:
                                                                AppTheme.onSurfaceVerySubtle(
                                                                  context,
                                                                ),
                                                            size: 18,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            14,
                                                          ),
                                                    ),
                                                    elevation: 8,
                                                    color: theme
                                                        .colorScheme
                                                        .surface,
                                                    onSelected: (value) {
                                                      if (value == 'resend') {
                                                        _resend(r);
                                                      } else if (value ==
                                                          'export') {
                                                        _exportAsCurl(r);
                                                      } else if (value ==
                                                          'details') {
                                                        _showDetails(r);
                                                      } else if (value ==
                                                          'delete') {
                                                        _delete(r);
                                                      }
                                                    },
                                                    itemBuilder: (context) => [
                                                      PopupMenuItem(
                                                        value: 'resend',
                                                        height: 48,
                                                        child: Row(
                                                          children: [
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    6,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: Colors
                                                                    .blue
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                              ),
                                                              child: Icon(
                                                                Icons
                                                                    .send_rounded,
                                                                size: 16,
                                                                color: Colors
                                                                    .blue[400],
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 12,
                                                            ),
                                                            Text(
                                                              AppLocalizations.of(
                                                                context,
                                                              )!.resendNotification,
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      PopupMenuItem(
                                                        value: 'export',
                                                        height: 48,
                                                        child: Row(
                                                          children: [
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    6,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: Colors
                                                                    .orange
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                              ),
                                                              child: Icon(
                                                                Icons
                                                                    .code_rounded,
                                                                size: 16,
                                                                color: Colors
                                                                    .orange[400],
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 12,
                                                            ),
                                                            Text(
                                                              AppLocalizations.of(
                                                                context,
                                                              )!.exportAsCurl,
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      PopupMenuItem(
                                                        value: 'details',
                                                        height: 48,
                                                        child: Row(
                                                          children: [
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    6,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: Colors
                                                                    .teal
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                              ),
                                                              child: Icon(
                                                                Icons
                                                                    .info_outline,
                                                                size: 16,
                                                                color: Colors
                                                                    .teal[400],
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 12,
                                                            ),
                                                            Text(
                                                              AppLocalizations.of(
                                                                context,
                                                              )!.viewDetails,
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      PopupMenuItem(
                                                        value: 'delete',
                                                        height: 48,
                                                        child: Row(
                                                          children: [
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    6,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: Colors
                                                                    .red
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                              ),
                                                              child: Icon(
                                                                Icons
                                                                    .delete_outline_rounded,
                                                                size: 16,
                                                                color: Colors
                                                                    .red[400],
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 12,
                                                            ),
                                                            Text(
                                                              AppLocalizations.of(
                                                                context,
                                                              )!.deleteEntry,
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Text(
                                            "${AppLocalizations.of(context)!.seq} ${r.seqNumber}",
                                            style: TextStyle(
                                              color: AppTheme.onSurfaceSubtle(
                                                context,
                                              ),
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            "•",
                                            style: TextStyle(
                                              color:
                                                  AppTheme.onSurfaceVerySubtle(
                                                    context,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            "$payloadLength ${AppLocalizations.of(context)!.bytes}",
                                            style: TextStyle(
                                              color: AppTheme.onSurfaceSubtle(
                                                context,
                                              ),
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            "•",
                                            style: TextStyle(
                                              color:
                                                  AppTheme.onSurfaceVerySubtle(
                                                    context,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            DateFormat(
                                              "yyyy-MM-dd HH:mm:ss",
                                            ).format(
                                              DateTime.fromMillisecondsSinceEpoch(
                                                r.timestamp,
                                              ),
                                            ),
                                            style: TextStyle(
                                              color: AppTheme.onSurfaceSubtle(
                                                context,
                                              ),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
