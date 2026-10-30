import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../adapter/euicc_adapter.dart';
import '../adapter/composite_adapter.dart';
import '../logic/profile_manager.dart';
import '../models/asn1/rsp_definitions.g.dart';
import '../theme/app_theme.dart';
import '../settings/app_settings.dart';
import '../utils/hex_utils.dart';
import '../utils/iccid_formatter.dart';
import '../services/profile_metadata_service.dart';
import '../services/notification_service.dart';
import '../services/database_service.dart';

import '../widgets/common/premium_dialogs.dart';
import '../widgets/styled_header_scaffold.dart';
import '../widgets/notifications/notification_card.dart';
import '../widgets/notifications/notification_details_dialog.dart';
import 'notification_history_page.dart';
import 'settings/notifications_settings_page.dart';
import 'package:logging/logging.dart';
import '../l10n/app_localizations.dart';

// Custom HttpClient to disable SSL validation
class CustomHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        return true;
      };
  }
}

class NotificationsScreen extends StatefulWidget {
  final Reader reader;
  final String? initialEid;

  const NotificationsScreen({super.key, required this.reader, this.initialEid});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static final Logger _log = Logger('NotificationsScreen');
  static const _removeAnimationDuration = Duration(milliseconds: 520);
  bool _loading = false;
  List<PendingNotification> _notifications = [];
  Map<int, String> _notificationStatus =
      {}; // seq -> 'on-card', 'sent', 'failed'
  final Map<String, ProfileMetadata?> _profileMetadataCache = {};
  final Set<int> _removingSeqs = {};
  String? _error;
  bool _isProcessing = false; // Prevent recursive processing
  String? _eid;
  int _statusRefreshGeneration = 0;

  @override
  void initState() {
    super.initState();
    _eid = widget.initialEid;
    NotificationService().currentNotifications.addListener(
      _onNotificationsChanged,
    );
    NotificationService().removedSeq.addListener(_onNotificationRemoved);
    NotificationService().sentSeq.addListener(_onNotificationSent);
    _seedCurrentNotifications();
    _primeAndLoadNotifications();
  }

  @override
  void dispose() {
    NotificationService().currentNotifications.removeListener(
      _onNotificationsChanged,
    );
    NotificationService().removedSeq.removeListener(_onNotificationRemoved);
    NotificationService().sentSeq.removeListener(_onNotificationSent);
    super.dispose();
  }

  void _onNotificationsChanged() {
    if (!mounted || _eid == null || NotificationService().currentEid != _eid) {
      return;
    }
    final newList = _retainRemovingNotifications(
      NotificationService().currentNotifications.value,
    );

    // We need to update _notificationStatus too
    // This is a bit inefficient to do on every change, but for small lists it's fine.
    // Better would be to pass EID and do the DB check again.
    _refreshStatusMap(newList);
  }

  List<PendingNotification> _retainRemovingNotifications(
    List<PendingNotification> incoming,
  ) {
    if (_removingSeqs.isEmpty || _notifications.isEmpty) {
      return incoming;
    }

    final incomingSeqs = incoming
        .map((n) => ProfileManager.extractMetadata(n)?.seqNumber)
        .whereType<int>()
        .toSet();
    final merged = List<PendingNotification>.from(incoming);

    for (final notification in _notifications) {
      final seq = ProfileManager.extractMetadata(notification)?.seqNumber;
      if (seq != null &&
          _removingSeqs.contains(seq) &&
          !incomingSeqs.contains(seq)) {
        merged.add(notification);
      }
    }

    return merged;
  }

  void _onNotificationRemoved() {
    final seq = NotificationService().removedSeq.value;
    if (!mounted ||
        seq == null ||
        _eid == null ||
        NotificationService().currentEid != _eid) {
      return;
    }
    if (!_notifications.any(
      (n) => (ProfileManager.extractMetadata(n)?.seqNumber ?? -1) == seq,
    )) {
      return;
    }

    setState(() {
      _removingSeqs.add(seq);
    });

    Future.delayed(_removeAnimationDuration, () {
      if (!mounted) return;
      setState(() {
        _notifications.removeWhere(
          (n) => (ProfileManager.extractMetadata(n)?.seqNumber ?? -1) == seq,
        );
        _notificationStatus.remove(seq);
        _removingSeqs.remove(seq);
      });
    });
  }

  void _onNotificationSent() {
    final seq = NotificationService().sentSeq.value;
    if (!mounted ||
        seq == null ||
        _eid == null ||
        NotificationService().currentEid != _eid) {
      return;
    }
    if (!_notifications.any(
      (n) => (ProfileManager.extractMetadata(n)?.seqNumber ?? -1) == seq,
    )) {
      return;
    }

    setState(() {
      _notificationStatus[seq] = 'sent';
    });
  }

  void _seedCurrentNotifications() {
    final current = NotificationService().currentNotifications.value;
    if (_eid == null ||
        NotificationService().currentEid != _eid ||
        current.isEmpty) {
      return;
    }

    final sortedList = List<PendingNotification>.from(current);
    sortedList.sort((a, b) {
      final seqA = ProfileManager.extractMetadata(a)?.seqNumber ?? -1;
      final seqB = ProfileManager.extractMetadata(b)?.seqNumber ?? -1;
      return seqB.compareTo(seqA);
    });

    final statusMap = <int, String>{};
    for (final n in sortedList) {
      final seq = ProfileManager.extractMetadata(n)?.seqNumber ?? -1;
      if (seq != -1) statusMap[seq] = 'on-card';
    }

    _notifications = sortedList;
    _notificationStatus = statusMap;
    unawaited(_preloadProfileMetadata(sortedList));
  }

  Future<void> _primeAndLoadNotifications() async {
    await _loadNotifications(skipProcessing: !_shouldAutoProcessOnOpen());
  }

  bool _shouldAutoProcessOnOpen() {
    final settings = AppSettings();
    return settings.notifProcessInitialLoad &&
        settings.isAnyNotificationProcessingEnabled &&
        !NotificationService().pauseRequestedByUser;
  }

  Future<void> _startNotificationProcessing() async {
    if (_isProcessing || NotificationService().isProcessing.value) {
      NotificationService().togglePause();
      return;
    }

    if (NotificationService().isPaused.value) {
      NotificationService().togglePause();
    }

    await _loadNotifications(skipProcessing: false);
  }

  Future<void> _preloadProfileMetadata(List<PendingNotification> list) async {
    final iccids = list
        .map(ProfileManager.extractMetadata)
        .whereType<NotificationMetadata>()
        .map(
          (m) => m.iccid != null
              ? HexUtils.swapNibbles(HexUtils.bytesToHex(m.iccid!))
              : null,
        )
        .whereType<String>()
        .where((iccid) => !_profileMetadataCache.containsKey(iccid))
        .toSet();

    if (iccids.isEmpty) return;

    try {
      final service = await ProfileMetadataService.getInstance();
      final loaded = <String, ProfileMetadata?>{};
      for (final iccid in iccids) {
        loaded[iccid] = await service.getProfile(iccid);
      }
      if (!mounted) return;
      setState(() {
        _profileMetadataCache.addAll(loaded);
      });
    } catch (e) {
      _log.warning("Failed to preload notification profile metadata: $e");
    }
  }

  Future<void> _refreshStatusMap(List<PendingNotification> list) async {
    final generation = ++_statusRefreshGeneration;
    if (_eid == null) {
      final statusMap = _buildDefaultStatusMap(list);
      final sortedList = _sortNotifications(list);
      if (mounted) {
        setState(() {
          _notifications = sortedList;
          _notificationStatus = statusMap;
          _loading = false;
        });
      }
      unawaited(_preloadProfileMetadata(list));
      return;
    }
    try {
      final dbNotifs = await DatabaseService().getNotifications(_eid!);
      final sent = await DatabaseService().getSentNotificationSequences(_eid!);
      if (!mounted || generation != _statusRefreshGeneration) return;
      final Map<int, int> dbStatusMap = {
        for (var r in dbNotifs) r.seqNumber: r.status,
      };

      final Map<int, String> statusMap = {};
      for (final n in list) {
        final seq = ProfileManager.extractMetadata(n)?.seqNumber ?? -1;
        if (seq != -1) {
          final dbStatus = dbStatusMap[seq];
          statusMap[seq] = sent.contains(seq)
              ? 'sent'
              : (dbStatus == 2 ? 'failed' : 'on-card');
        }
      }

      if (mounted) {
        // Sort the list
        final sortedList = List<PendingNotification>.from(list);
        sortedList.sort((a, b) {
          final seqA = ProfileManager.extractMetadata(a)?.seqNumber ?? -1;
          final seqB = ProfileManager.extractMetadata(b)?.seqNumber ?? -1;
          return seqB.compareTo(seqA);
        });

        setState(() {
          _notifications = sortedList;
          _notificationStatus = statusMap;
        });
      }
      unawaited(_preloadProfileMetadata(list));
    } catch (e) {
      _log.warning("Failed to refresh status map: $e");
    }
  }

  List<PendingNotification> _sortNotifications(List<PendingNotification> list) {
    final sortedList = List<PendingNotification>.from(list);
    sortedList.sort((a, b) {
      final seqA = ProfileManager.extractMetadata(a)?.seqNumber ?? -1;
      final seqB = ProfileManager.extractMetadata(b)?.seqNumber ?? -1;
      return seqB.compareTo(seqA);
    });
    return sortedList;
  }

  Map<int, String> _buildDefaultStatusMap(List<PendingNotification> list) {
    final statusMap = <int, String>{};
    for (final n in list) {
      final seq = ProfileManager.extractMetadata(n)?.seqNumber ?? -1;
      if (seq != -1) statusMap[seq] = 'on-card';
    }
    return statusMap;
  }

  bool _willDeleteNotification(NotificationMetadata metadata) {
    final settings = AppSettings();
    final op = metadata.profileManagementOperation;
    final dataByte = op?.value ?? 0;

    if ((dataByte & NotificationEvent.notificationInstall) != 0) {
      return settings.notifAutoRemoveInstall;
    }
    if ((dataByte & NotificationEvent.notificationLocalEnable) != 0) {
      return settings.notifAutoRemoveEnable ||
          settings.notifDeleteWithoutSendingEnable;
    }
    if ((dataByte & NotificationEvent.notificationLocalDisable) != 0) {
      return settings.notifAutoRemoveDisable ||
          settings.notifDeleteWithoutSendingDisable;
    }
    if ((dataByte & NotificationEvent.notificationLocalDelete) != 0) {
      return settings.notifAutoRemoveDelete;
    }
    return false;
  }

  Future<void> _loadNotifications({bool skipProcessing = true}) async {
    // Only show full-screen loading if we don't have data yet
    if (_notifications.isEmpty) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() {
        _error = null;
      });
    }

    final settings = AppSettings();
    final adapter = CompositeAdapter();

    try {
      final manager = ProfileManager(adapter);

      // Selection and notification APDUs share one card reservation.
      await adapter.runExclusive(() async {
        await adapter.connect(widget.reader);
        final channel = await manager.openSession();
        try {
          // 1. Initial Fetch
          final cardNotifs = await manager.retrieveNotifications(
            useChannel: channel,
          );

          final eid = await manager
              .getEid(useChannel: channel)
              .catchError((_) => "Unknown");
          _eid = eid;

          // Identify statuses from DB
          final dbNotifs = await DatabaseService().getNotifications(eid);
          final sent = await DatabaseService().getSentNotificationSequences(
            eid,
          );
          final Map<int, int> dbStatusMap = {
            for (var r in dbNotifs) r.seqNumber: r.status,
          };
          final Map<int, String> statusMap = {};
          final pendingCardNotifs = <PendingNotification>[];
          for (final n in cardNotifs) {
            final seq = ProfileManager.extractMetadata(n)?.seqNumber ?? -1;
            if (seq != -1) {
              final dbStatus = dbStatusMap[seq];
              pendingCardNotifs.add(n);
              statusMap[seq] = sent.contains(seq)
                  ? 'sent'
                  : (dbStatus == 2 ? 'failed' : 'on-card');
            }
          }

          // Initial Sync (Current Card only)
          await NotificationService().syncAndGetCount(eid, cardNotifs);

          // Convert and sort
          final list = _sortNotifications(pendingCardNotifs);
          unawaited(_preloadProfileMetadata(list));

          // Update UI: Unfreeze and show what we found
          if (mounted) {
            setState(() {
              _notifications = list;
              _notificationStatus = statusMap;
              _loading = false; // UI is now interactive
            });
          }

          // 2. Conditional Processing (Background-ish but on same channel)
          if (settings.isAnyNotificationProcessingEnabled &&
              !_isProcessing &&
              !skipProcessing) {
            _isProcessing = true;
            try {
              _log.info(
                'Starting synchronized notification processing flow...',
              );
              await NotificationService().processPendingNotifications(
                manager,
                channel,
                readerName: widget.reader.id,
                eid: eid,
                autoSendInstall: settings.notifAutoSendInstall,
                autoRemoveInstall: settings.notifAutoRemoveInstall,
                autoSendEnable: settings.notifAutoSendEnable,
                autoRemoveEnable: settings.notifAutoRemoveEnable,
                deleteWithoutSendingEnable:
                    settings.notifDeleteWithoutSendingEnable,
                autoSendDisable: settings.notifAutoSendDisable,
                autoRemoveDisable: settings.notifAutoRemoveDisable,
                deleteWithoutSendingDisable:
                    settings.notifDeleteWithoutSendingDisable,
                autoSendDelete: settings.notifAutoSendDelete,
                autoRemoveDelete: settings.notifAutoRemoveDelete,
              );
              _log.info('Synchronized processing completed.');
            } finally {
              _isProcessing = false;
            }

            // 3. Final Re-sync after processing
            final finalNotifs = await manager.retrieveNotifications(
              useChannel: channel,
            );
            await NotificationService().syncAndGetCount(eid, finalNotifs);

            // Re-fetch statuses
            final updatedDbNotifs = await DatabaseService().getNotifications(
              eid,
            );
            final finalSent = await DatabaseService()
                .getSentNotificationSequences(eid);
            final updatedDbStatusMap = {
              for (var r in updatedDbNotifs) r.seqNumber: r.status,
            };
            final updatedStatusMap = <int, String>{};
            final pendingFinalNotifs = <PendingNotification>[];
            for (final n in finalNotifs) {
              final seq = ProfileManager.extractMetadata(n)?.seqNumber ?? -1;
              if (seq != -1) {
                final dbStatus = updatedDbStatusMap[seq];
                pendingFinalNotifs.add(n);
                updatedStatusMap[seq] = finalSent.contains(seq)
                    ? 'sent'
                    : (dbStatus == 2 ? 'failed' : 'on-card');
              }
            }

            // Sort final list
            final finalList = _sortNotifications(pendingFinalNotifs);
            unawaited(_preloadProfileMetadata(finalList));

            if (mounted) {
              setState(() {
                _notifications = finalList;
                _notificationStatus = updatedStatusMap;
              });
            }
          }
        } finally {
          await channel.close();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _confirmDelete(int seqNumber) async {
    final confirm = await PremiumDialogs.showConfirmDialog(
      context: context,
      title: AppLocalizations.of(context)!.deleteNotification,
      message: AppLocalizations.of(
        context,
      )!.confirmDeleteNotification(seqNumber),
      confirmLabel: AppLocalizations.of(context)!.delete,
      isDestructive: true,
    );

    if (confirm == true) {
      _removeNotification(seqNumber);
    }
  }

  Future<void> _removeNotification(int seqNumber) async {
    final adapter = CompositeAdapter();
    try {
      await adapter.runExclusive(() async {
        await adapter.connect(widget.reader);
        final manager = ProfileManager(adapter);
        final channel = await manager.openSession();
        try {
          await NotificationService().removeFromCard(
            manager,
            channel,
            seqNumber,
            expectedEid: _eid,
          );
        } finally {
          await channel.close();
        }
      });
      await _loadNotifications(skipProcessing: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.notificationRemoved),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToRemove(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getOperationIcon(NotificationEvent? op) {
    if (op == null) return Icons.help_outline_rounded;

    int dataByte = op.value;

    if ((dataByte & NotificationEvent.notificationInstall) != 0) {
      return Icons.download_rounded; // Install
    }
    if ((dataByte & NotificationEvent.notificationLocalEnable) != 0) {
      return Icons.check_circle_outline_rounded; // Enable
    }
    if ((dataByte & NotificationEvent.notificationLocalDisable) != 0) {
      return Icons.cancel_outlined; // Disable
    }
    if ((dataByte & NotificationEvent.notificationLocalDelete) != 0) {
      return Icons.delete_outline_rounded; // Delete
    }
    if ((dataByte & NotificationEvent.notificationRpmEnable) != 0) {
      return Icons.cloud_upload_outlined; // RPM Enable
    }
    if ((dataByte & NotificationEvent.notificationRpmDisable) != 0) {
      return Icons.cloud_off_outlined; // RPM Disable
    }
    if ((dataByte & NotificationEvent.notificationRpmDelete) != 0) {
      return Icons.cloud_done_outlined; // RPM Delete
    }
    if ((dataByte & NotificationEvent.loadRpmPackageResult) != 0) {
      return Icons.inventory_2_outlined; // Load RPM
    }

    return Icons.help_outline_rounded;
  }

  Color _getOperationColor(NotificationEvent? op) {
    if (op == null) return Colors.grey;

    int dataByte = op.value;

    if ((dataByte & NotificationEvent.notificationInstall) != 0) {
      return Colors.blue; // Install
    }
    if ((dataByte & NotificationEvent.notificationLocalEnable) != 0) {
      return Colors.green; // Enable
    }
    if ((dataByte & NotificationEvent.notificationLocalDisable) != 0) {
      return Colors.orange; // Disable
    }
    if ((dataByte & NotificationEvent.notificationLocalDelete) != 0) {
      return Colors.red; // Delete
    }
    if ((dataByte & NotificationEvent.notificationRpmEnable) != 0) {
      return Colors.purple; // RPM Enable
    }
    if ((dataByte & NotificationEvent.notificationRpmDisable) != 0) {
      return Colors.deepOrange; // RPM Disable
    }
    if ((dataByte & NotificationEvent.notificationRpmDelete) != 0) {
      return Colors.pink; // RPM Delete
    }
    if ((dataByte & NotificationEvent.loadRpmPackageResult) != 0) {
      return Colors.teal; // Load RPM
    }

    return Colors.grey;
  }

  String _getOperationName(NotificationEvent? op, BuildContext context) {
    if (op == null) return AppLocalizations.of(context)!.unknown;
    int dataByte = op.value;
    final l10n = AppLocalizations.of(context)!;

    if ((dataByte & NotificationEvent.notificationInstall) != 0) {
      return l10n.notifTypeInstall;
    }
    if ((dataByte & NotificationEvent.notificationLocalEnable) != 0) {
      return l10n.notifTypeEnable;
    }
    if ((dataByte & NotificationEvent.notificationLocalDisable) != 0) {
      return l10n.notifTypeDisable;
    }
    if ((dataByte & NotificationEvent.notificationLocalDelete) != 0) {
      return l10n.notifTypeDelete;
    }
    if ((dataByte & NotificationEvent.notificationRpmEnable) != 0) {
      return l10n.notifTypeRpmEnable;
    }
    if ((dataByte & NotificationEvent.notificationRpmDisable) != 0) {
      return l10n.notifTypeRpmDisable;
    }
    if ((dataByte & NotificationEvent.notificationRpmDelete) != 0) {
      return l10n.notifTypeRpmDelete;
    }
    if ((dataByte & NotificationEvent.loadRpmPackageResult) != 0) {
      return l10n.notifTypeLoadRpm;
    }

    return l10n.unknown;
  }

  void _generateAndCopyCurl(PendingNotification notification, String? address) {
    try {
      final encoded = base64Encode(notification.encode());
      final curl =
          'curl -X POST "https://$address/gsma/rsp2/es9plus/handleNotification" \\\n'
          ' -H "User-Agent: gsma-rsp-lpad" \\\n'
          ' -H "Content-Type: application/json" \\\n'
          ' -H "X-Admin-Protocol: gsma/rsp/v2.2.0" \\\n'
          ' -k -d \'{"pendingNotification": "$encoded"}\'';

      Clipboard.setData(ClipboardData(text: curl));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.curlCopied)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.failedToGenerateCurl(e.toString()),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendNotification(
    PendingNotification notification,
    String? address,
  ) async {
    if (address == null || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.noNotificationAddress),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show premium loading indicator
    PremiumDialogs.showLoadingDialog(
      context: context,
      message: AppLocalizations.of(context)!.sendingNotification,
    );

    try {
      final adapter = CompositeAdapter();
      final success = await adapter.runExclusive(() async {
        await adapter.connect(widget.reader);
        final manager = ProfileManager(adapter);
        final channel = await manager.openSession();
        try {
          final eid = await manager.getEid(useChannel: channel);
          if (_eid != null && _eid != 'Unknown' && eid != _eid) {
            throw StateError('The selected eUICC changed before sending');
          }
          final resolved = notification.asn1 == null
              ? await manager.resolveNotification(
                  notification,
                  useChannel: channel,
                )
              : notification;
          final sent = await NotificationService().sendNotification(
            resolved,
            address,
            eid: eid,
          );
          if (sent &&
              _willDeleteNotification(
                ProfileManager.extractMetadata(resolved)!,
              )) {
            try {
              await NotificationService().removeFromCard(
                manager,
                channel,
                ProfileManager.extractMetadata(resolved)!.seqNumber!,
                expectedEid: eid,
              );
            } catch (error) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(
                        context,
                      )!.failedToRemove(error.toString()),
                    ),
                  ),
                );
              }
            }
          }
          return sent;
        } finally {
          await channel.close();
        }
      });

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.notifSentSuccessfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _loadNotifications(); // Refresh to update status and counter
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.failedToSendNotification,
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.errorSendingNotification(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    int unsentCount = 0;
    for (final seq in _notificationStatus.keys) {
      final status = _notificationStatus[seq];
      if (status == 'on-card' || status == 'failed') {
        unsentCount++;
      }
    }

    return StyledHeaderScaffold(
      title: AppLocalizations.of(context)!.notifications,
      subtitle: _notifications.isNotEmpty
          ? AppLocalizations.of(context)!.pendingCount(unsentCount)
          : null,
      actions: [
        ValueListenableBuilder<bool>(
          valueListenable: NotificationService().isProcessing,
          builder: (context, globalProcessing, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // History button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: globalProcessing
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationHistoryPage(),
                            ),
                          ),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.history_rounded,
                          color: globalProcessing
                              ? kPrimaryColor.withValues(alpha: 0.5)
                              : kPrimaryColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Settings button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: globalProcessing
                        ? null
                        : () =>
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const NotificationSettingsPage(),
                                ),
                              ).then((_) {
                                if (mounted) setState(() {});
                              }),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.settings_rounded,
                          color: globalProcessing
                              ? kPrimaryColor.withValues(alpha: 0.5)
                              : kPrimaryColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Refresh button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: globalProcessing ? null : _loadNotifications,
                    child: Ink(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.refresh_rounded,
                          color: globalProcessing
                              ? kPrimaryColor.withValues(alpha: 0.5)
                              : kPrimaryColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle(context),
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Icon(
                        Icons.sim_card,
                        size: 20,
                        color: AppTheme.onSurfaceSubtle(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.reader.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context)!.currentReader,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.onSurfaceSubtle(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: NotificationService().isProcessing,
                      builder: (context, isProcessing, _) {
                        return ValueListenableBuilder<bool>(
                          valueListenable: NotificationService().isPaused,
                          builder: (context, isPaused, _) {
                            return ValueListenableBuilder<int>(
                              valueListenable:
                                  NotificationService().pendingCount,
                              builder: (context, count, _) {
                                final hasNotifications =
                                    count > 0 || _notifications.isNotEmpty;
                                if (!hasNotifications && !isProcessing) {
                                  return const SizedBox.shrink();
                                }

                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(22),
                                        onTap: () {
                                          unawaited(
                                            _startNotificationProcessing(),
                                          );
                                        },
                                        child: Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: isPaused
                                                ? Colors.orange[500]!
                                                : Colors.blue[600]!,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isPaused
                                                  ? Colors.orange[200]!
                                                  : Colors.blue[200]!,
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    (isPaused
                                                            ? Colors.orange
                                                            : Colors.blue)
                                                        .withValues(
                                                          alpha: 0.28,
                                                        ),
                                                blurRadius: 10,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Icon(
                                              isPaused
                                                  ? Icons.play_arrow_rounded
                                                  : (isProcessing
                                                        ? Icons.pause_rounded
                                                        : Icons
                                                              .play_arrow_rounded),
                                              size: 26,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (count > 0)
                                      Positioned(
                                        right: -4,
                                        top: -4,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 18,
                                            minHeight: 18,
                                          ),
                                          child: Text(
                                            "$count",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);

    // We no longer mask the screen on loading, as all operations are disabled
    // when notifications are processing anyway. We show the content immediately.
    return Column(
      children: [
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        Expanded(child: _buildMainContent(context, theme)),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context, ThemeData theme) {
    if (_error != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.3 : 0.04,
                ),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: Colors.red[400],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.errorLoadingNotifications,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                _error!,
                style: TextStyle(
                  color: AppTheme.onSurfaceSubtle(context),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _loadNotifications,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.retry,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      if (_loading) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.loadingNotifications,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceSubtle(context),
                ),
              ),
            ],
          ),
        );
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSubtle(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: AppTheme.onSurfaceVerySubtle(context),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.noNotifications,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceSubtle(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.allCaughtUp,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.onSurfaceVerySubtle(context),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      // ignore: deprecated_member_use
      cacheExtent: 1000,
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notif = _notifications[index];
        final metadata = ProfileManager.extractMetadata(notif);

        if (metadata == null) {
          return _buildErrorCard(context);
        }

        final seq = metadata.seqNumber ?? -1;
        final op = _getOperationName(
          metadata.profileManagementOperation,
          context,
        );
        final opIcon = _getOperationIcon(metadata.profileManagementOperation);
        final opColor = _getOperationColor(metadata.profileManagementOperation);
        final rawIccid = metadata.iccid != null
            ? HexUtils.swapNibbles(HexUtils.bytesToHex(metadata.iccid!))
            : null;
        final addr = metadata.notificationAddress;

        final profileMeta = rawIccid != null
            ? _profileMetadataCache[rawIccid]
            : null;
        final cleanedIccid = rawIccid != null
            ? IccidFormatter.forDisplay(rawIccid)
            : null;
        final status = _notificationStatus[seq] ?? 'on-card';
        final isRemoving = _removingSeqs.contains(seq);
        final willDelete = _willDeleteNotification(metadata);

        return KeyedSubtree(
          key: ValueKey('notification-$seq'),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 1, end: isRemoving ? 0 : 1),
            duration: _removeAnimationDuration,
            curve: Curves.easeInOutCubic,
            builder: (context, factor, child) {
              final progress = factor.clamp(0.0, 1.0);
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: progress,
                  child: Opacity(
                    opacity: Curves.easeOut.transform(progress),
                    child: Transform.translate(
                      offset: Offset(32 * (1 - progress), -8 * (1 - progress)),
                      child: Transform.scale(
                        alignment: Alignment.centerRight,
                        scale: 0.96 + (0.04 * progress),
                        child: child,
                      ),
                    ),
                  ),
                ),
              );
            },
            child: ValueListenableBuilder<int?>(
              valueListenable: NotificationService().processingSeq,
              builder: (context, currentSeq, _) {
                final isThisProcessing = currentSeq == seq;
                return ValueListenableBuilder<bool>(
                  valueListenable: NotificationService().isProcessing,
                  builder: (context, globalProcessing, _) {
                    return RepaintBoundary(
                      child: NotificationCard(
                        notification: notif,
                        sequenceNumber: seq,
                        operationName: op,
                        operationIcon: opIcon,
                        operationColor: opColor,
                        profileName:
                            profileMeta?.displayName ??
                            cleanedIccid ??
                            AppLocalizations.of(context)!.unknownProfile,
                        iccid: cleanedIccid,
                        address: addr,
                        profileMetadata: profileMeta,
                        status: status,
                        isProcessing: isThisProcessing,
                        isDeleting: isThisProcessing && willDelete,
                        onTap: globalProcessing
                            ? () {}
                            : () => NotificationDetailsDialog.show(
                                context: context,
                                notification: notif,
                                sequence: seq,
                                operation: op,
                                operationColor: opColor,
                                profileName:
                                    profileMeta?.displayName ??
                                    cleanedIccid ??
                                    "Unknown Profile",
                                iccid: cleanedIccid,
                                address: addr,
                                metadata: profileMeta,
                              ),
                        onMenuSelected: globalProcessing
                            ? (v) {}
                            : (value) {
                                if (value == 'delete') {
                                  _confirmDelete(seq);
                                } else if (value == 'curl') {
                                  _generateAndCopyCurl(notif, addr);
                                } else if (value == 'send') {
                                  _sendNotification(notif, addr);
                                }
                              },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange[400],
            size: 20,
          ),
          const SizedBox(width: 12),
          const Text("Unknown Notification Format"),
        ],
      ),
    );
  }
}
