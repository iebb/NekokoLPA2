import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/asn1/rsp_definitions.g.dart';
import '../logic/profile_manager.dart';
import '../adapter/euicc_adapter.dart';
import '../adapter/se_hal_adapter.dart';
import '../utils/hex_utils.dart';
import 'database_service.dart';
import 'package:logging/logging.dart';
import '../services/smdp_client.dart';
import '../pages/profiles_screen.dart';

// Helper class for send result
class SendResult {
  final bool success;
  final int statusCode;
  final String body;
  SendResult(this.success, this.statusCode, this.body);
}

class NotificationService {
  static final Logger _log = Logger('NotificationService');
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final ValueNotifier<bool> isProcessing = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isPaused = ValueNotifier<bool>(false);
  bool _pauseRequestedByUser = false;
  bool get pauseRequestedByUser => _pauseRequestedByUser;
  final ValueNotifier<bool> isFetching = ValueNotifier<bool>(false);
  final ValueNotifier<int?> processingSeq = ValueNotifier<int?>(null);
  final ValueNotifier<int?> removedSeq = ValueNotifier<int?>(null);
  final ValueNotifier<int?> sentSeq = ValueNotifier<int?>(null);
  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);
  final ValueNotifier<List<PendingNotification>> currentNotifications =
      ValueNotifier<List<PendingNotification>>([]);

  Future<bool> sendNotification(
    PendingNotification notification,
    String address,
  ) async {
    try {
      await SmdpClient.post(
        smdpAddress: address,
        endpoint: 'handleNotification',
        bodyData: {'pendingNotification': base64Encode(notification.encode())},
        checkStatus:
            false, // SM-DP+ might return 204 or specific codes for notifications
      );
      return true;
    } catch (e) {
      _log.warning("Notification send failed: $e");
      return false;
    }
  }

  Future<SendResult> sendNotificationRaw(
    PendingNotification notification,
    String address,
  ) async {
    if (address.isEmpty) return SendResult(false, 0, "Empty address");

    try {
      final data = await SmdpClient.post(
        smdpAddress: address,
        endpoint: 'handleNotification',
        bodyData: {'pendingNotification': base64Encode(notification.encode())},
        checkStatus: false,
      );
      // If no exception, it's successful enough for now.
      // Note: SmdpClient.post currently throws if not 2xx.
      return SendResult(true, 200, jsonEncode(data));
    } catch (e) {
      return SendResult(false, 0, e.toString());
    }
  }

  Future<void> processPendingNotifications(
    ProfileManager manager,
    Channel? channel, {
    String? readerName,
    String? eid,
    required bool autoSendInstall,
    required bool autoRemoveInstall,
    required bool autoSendEnable,
    required bool autoRemoveEnable,
    required bool deleteWithoutSendingEnable,
    required bool autoSendDisable,
    required bool autoRemoveDisable,
    required bool deleteWithoutSendingDisable,
    required bool autoSendDelete,
    required bool autoRemoveDelete,
  }) async {
    if (isProcessing.value) return;
    isProcessing.value = true;

    try {
      // Use adapter.runExclusive (if Ccid) or just ensure single channel.
      // We'll wrap the whole flow in a single session if channel is null.
      if (channel == null) {
        await manager.adapter.runExclusive(() async {
          final ch = await manager.openSession();
          try {
            await _runProcess(
              manager,
              ch,
              readerName: readerName,
              eid: eid,
              autoSendInstall: autoSendInstall,
              autoRemoveInstall: autoRemoveInstall,
              autoSendEnable: autoSendEnable,
              autoRemoveEnable: autoRemoveEnable,
              deleteWithoutSendingEnable: deleteWithoutSendingEnable,
              autoSendDisable: autoSendDisable,
              autoRemoveDisable: autoRemoveDisable,
              deleteWithoutSendingDisable: deleteWithoutSendingDisable,
              autoSendDelete: autoSendDelete,
              autoRemoveDelete: autoRemoveDelete,
            );
          } finally {
            await ch.close();
          }
        });
      } else {
        await _runProcess(
          manager,
          channel,
          readerName: readerName,
          eid: eid,
          autoSendInstall: autoSendInstall,
          autoRemoveInstall: autoRemoveInstall,
          autoSendEnable: autoSendEnable,
          autoRemoveEnable: autoRemoveEnable,
          deleteWithoutSendingEnable: deleteWithoutSendingEnable,
          autoSendDisable: autoSendDisable,
          autoRemoveDisable: autoRemoveDisable,
          deleteWithoutSendingDisable: deleteWithoutSendingDisable,
          autoSendDelete: autoSendDelete,
          autoRemoveDelete: autoRemoveDelete,
        );
      }
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      final isConnectivity =
          errStr.contains('secure element') ||
          errStr.contains('not_connected') ||
          errStr.contains('connection_failed') ||
          errStr.contains('channel_failed') ||
          errStr.contains('proactiverefreshexception') ||
          (ProfilesScreen.isSwitchingGlobal &&
              errStr.contains('no supported euicc'));

      if (ProfilesScreen.isSwitchingGlobal && isConnectivity) {
        _log.info(
          "Connectivity error while fetching notifications (switching profile): $e",
        );
        return;
      }
      _log.severe("Error fetching notifications: $e");
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> _runProcess(
    ProfileManager manager,
    Channel channel, {
    String? readerName,
    String? eid,
    required bool autoSendInstall,
    required bool autoRemoveInstall,
    required bool autoSendEnable,
    required bool autoRemoveEnable,
    required bool deleteWithoutSendingEnable,
    required bool autoSendDisable,
    required bool autoRemoveDisable,
    required bool deleteWithoutSendingDisable,
    required bool autoSendDelete,
    required bool autoRemoveDelete,
  }) async {
    final anyEnabled =
        autoSendInstall ||
        autoSendEnable ||
        deleteWithoutSendingEnable ||
        autoSendDisable ||
        deleteWithoutSendingDisable ||
        autoSendDelete;

    try {
      isFetching.value = true;
      final currentEid =
          eid ??
          await manager
              .getEid(useChannel: channel)
              .catchError((_) => "Unknown");
      final notifications = await manager.retrieveNotifications(
        useChannel: channel,
      );
      isFetching.value = false;

      // Perform sync and update pending count (Current Card only)
      await syncAndGetCount(currentEid, notifications);

      if (notifications.isEmpty) return;

      if (anyEnabled) {
        // Process notifications
        await _backgroundProcess(
          notifications,
          manager,
          readerName,
          eid: currentEid,
          channel: channel,
          autoSendInstall: autoSendInstall,
          autoRemoveInstall: autoRemoveInstall,
          autoSendEnable: autoSendEnable,
          autoRemoveEnable: autoRemoveEnable,
          deleteWithoutSendingEnable: deleteWithoutSendingEnable,
          autoSendDisable: autoSendDisable,
          autoRemoveDisable: autoRemoveDisable,
          deleteWithoutSendingDisable: deleteWithoutSendingDisable,
          autoSendDelete: autoSendDelete,
          autoRemoveDelete: autoRemoveDelete,
        );
      }
    } finally {
      // isFetching already set locally above if successful or here if failed
      isFetching.value = false;
    }
  }

  Future<void> _backgroundProcess(
    List<PendingNotification> notifications,
    ProfileManager manager,
    String? readerName, {
    String? eid,
    Channel? channel,
    required bool autoSendInstall,
    required bool autoRemoveInstall,
    required bool autoSendEnable,
    required bool autoRemoveEnable,
    required bool deleteWithoutSendingEnable,
    required bool autoSendDisable,
    required bool autoRemoveDisable,
    required bool deleteWithoutSendingDisable,
    required bool autoSendDelete,
    required bool autoRemoveDelete,
  }) async {
    isProcessing.value = true;
    final currentEid = eid ?? "Unknown";
    final seqsToRemove = <int>{};
    final seqToIccid = <int, String>{};
    final processedAsSent = <int>{};

    try {
      // HAL automatic send-only flows must not remove historical pending deletes.
      final halSendOnly =
          (channel is HalDownloadChannel ||
              manager.adapter.connectedReader?.source is SeHalAdapter) &&
          !autoRemoveInstall &&
          !autoRemoveEnable &&
          !deleteWithoutSendingEnable &&
          !autoRemoveDisable &&
          !deleteWithoutSendingDisable &&
          !autoRemoveDelete;
      try {
        final pendingDeletes = await DatabaseService()
            .getDeletePendingNotifications(currentEid);
        for (final p in halSendOnly ? <NotificationRecord>[] : pendingDeletes) {
          seqsToRemove.add(p.seqNumber);
          seqToIccid[p.seqNumber] = p.iccid;
        }
      } catch (e) {
        _log.warning("Error collecting pending deletes: $e");
      }

      final jobsByRsp = <String, List<PendingNotification>>{};

      for (var n in notifications) {
        final metadata = ProfileManager.extractMetadata(n);
        if (metadata == null) continue;

        String iccid = metadata.iccid != null
            ? HexUtils.swapNibbles(HexUtils.bytesToHex(metadata.iccid!))
            : "Unknown";
        int seq = metadata.seqNumber ?? -1;

        // Ensure resolution and backup
        final existing = await DatabaseService().getNotification(
          currentEid,
          seq,
          iccid,
        );

        if (existing == null) {
          // No backup or skeleton in DB (shouldn't happen but for safety)
          if (n.asn1 == null) {
            // Skeleton from card -> Resolve
            _log.info("Fetching full signed notification for backup: seq=$seq");
            n = await manager.resolveNotification(n, useChannel: channel);
          }
          // Backup it now
          _log.info("Backing up notification: seq=$seq iccid=$iccid");
          await DatabaseService().saveNotification(
            NotificationRecord(
              eid: currentEid,
              iccid: iccid,
              seqNumber: seq,
              content: base64Encode(n.encode()),
              timestamp: DateTime.now().millisecondsSinceEpoch,
              status: existing?.status ?? 0,
              notificationServer: metadata.notificationAddress,
              notificationType: _getNotificationType(metadata),
              deletePending: 0,
            ),
          );
        } else if (n.asn1 == null) {
          // Skeleton from card but we HAVE backup in DB -> Resolve from DB
          _log.info("Restoring notification from local backup: seq=$seq");
          n = PendingNotification.decode(base64Decode(existing.content));
        }

        final op = metadata.profileManagementOperation;
        int dataByte = op?.value ?? 0;

        bool shouldSend = false;
        bool shouldRemove = false;
        bool shouldDeleteWithoutSending = false;

        if ((dataByte & NotificationEvent.notificationInstall) != 0) {
          shouldSend = autoSendInstall;
          shouldRemove = autoRemoveInstall;
        } else if ((dataByte & NotificationEvent.notificationLocalEnable) !=
            0) {
          shouldSend = autoSendEnable;
          shouldRemove = autoRemoveEnable;
          shouldDeleteWithoutSending = deleteWithoutSendingEnable;
        } else if ((dataByte & NotificationEvent.notificationLocalDisable) !=
            0) {
          shouldSend = autoSendDisable;
          shouldRemove = autoRemoveDisable;
          shouldDeleteWithoutSending = deleteWithoutSendingDisable;
        } else if ((dataByte & NotificationEvent.notificationLocalDelete) !=
            0) {
          shouldSend = autoSendDelete;
          shouldRemove = autoRemoveDelete;
        }

        if (shouldDeleteWithoutSending && seq != -1) {
          _log.info(
            "Deleting notification without sending: seq=$seq iccid=$iccid",
          );
          await DatabaseService().updateNotificationStatus(
            currentEid,
            seq,
            iccid,
            3, // status 3
          );

          seqsToRemove.add(seq);
          seqToIccid[seq] = iccid;
          continue;
        }

        if (shouldSend && metadata.notificationAddress != null) {
          final isSent = await DatabaseService().isNotificationSent(
            currentEid,
            seq,
            iccid,
          );
          if (isSent) {
            processedAsSent.add(seq);
            if (shouldRemove && seq != -1) {
              seqsToRemove.add(seq);
              seqToIccid[seq] = iccid;
            }
          } else {
            jobsByRsp
                .putIfAbsent(metadata.notificationAddress!, () => [])
                .add(n);
          }
        } else if (shouldRemove && seq != -1) {
          // We should only remove if it doesn't need sending (or it's already sent)
          seqsToRemove.add(seq);
          seqToIccid[seq] = iccid;
        }
      }

      if (jobsByRsp.isNotEmpty) {
        _log.info(
          "Processing sends for ${jobsByRsp.length} RSPs in parallel...",
        );
        await Future.wait(
          jobsByRsp.entries.map((entry) async {
            final address = entry.key;
            final list = entry.value;

            for (final n in list) {
              await _waitWhilePaused();
              final metadata = ProfileManager.extractMetadata(n);
              if (metadata == null) continue;

              String iccid = metadata.iccid != null
                  ? HexUtils.swapNibbles(HexUtils.bytesToHex(metadata.iccid!))
                  : "Unknown";
              int seq = metadata.seqNumber ?? -1;

              // Re-evaluate remove logic
              final op = metadata.profileManagementOperation;
              int dataByte = op?.value ?? 0;
              bool shouldRemove = false;
              if ((dataByte & NotificationEvent.notificationInstall) != 0) {
                shouldRemove = autoRemoveInstall;
              } else if ((dataByte &
                      NotificationEvent.notificationLocalEnable) !=
                  0) {
                shouldRemove = autoRemoveEnable;
              } else if ((dataByte &
                      NotificationEvent.notificationLocalDisable) !=
                  0) {
                shouldRemove = autoRemoveDisable;
              } else if ((dataByte &
                      NotificationEvent.notificationLocalDelete) !=
                  0) {
                shouldRemove = autoRemoveDelete;
              }

              try {
                await DatabaseService().saveNotification(
                  NotificationRecord(
                    eid: currentEid,
                    iccid: iccid,
                    seqNumber: seq,
                    content: base64Encode(n.encode()),
                    timestamp: DateTime.now().millisecondsSinceEpoch,
                    status: 0,
                    notificationServer: address,
                    notificationType: _getNotificationType(metadata),
                    deletePending: 0,
                  ),
                );

                final result = await sendNotificationRaw(n, address);
                await DatabaseService().updateNotificationStatus(
                  currentEid,
                  seq,
                  iccid,
                  result.success ? 1 : 2,
                  responseCode: result.statusCode,
                  responseContent: result.body,
                );

                if (result.success) {
                  processedAsSent.add(seq);
                  sentSeq.value = seq;
                  if (pendingCount.value > 0) pendingCount.value--;

                  if (shouldRemove && seq != -1) {
                    seqsToRemove.add(seq);
                    seqToIccid[seq] = iccid;
                  }
                }
              } catch (e) {
                _log.warning("Error in send for RSP $address seq $seq: $e");
              }
            }
          }),
        );
      }

      // 2. Perform Batch Removal
      if (seqsToRemove.isNotEmpty) {
        _log.info(
          "Performing removal of ${seqsToRemove.length} notifications...",
        );
        final uniqueSeqs = seqsToRemove.toList();

        for (final seq in uniqueSeqs) {
          try {
            await _waitWhilePaused();
            processingSeq.value = seq;

            final activeChannel = channel;
            if (activeChannel == null) {
              _log.warning("No channel for removal of $seq");
              continue;
            }

            final status = await _performRemoval(manager, activeChannel, seq);
            if (status ==
                NotificationSentResponse_deleteNotificationStatus
                    .undefinedError) {
              _log.warning(
                "Received undefinedError (127) while removing notification $seq.",
              );
            }
            final iccid = seqToIccid[seq] ?? "Unknown";
            await DatabaseService().setDeletePending(
              currentEid,
              seq,
              iccid,
              false,
            );

            if (!processedAsSent.contains(seq)) {
              if (pendingCount.value > 0) pendingCount.value--;
            }
            removedSeq.value = seq;
          } catch (e) {
            _log.severe("Failed to remove notification $seq: $e");
            final iccid = seqToIccid[seq] ?? "Unknown";
            await DatabaseService().setDeletePending(
              currentEid,
              seq,
              iccid,
              true,
            );
          } finally {
            processingSeq.value = null;
          }
        }
      }

      // Final Sync
      try {
        _log.info("Process finished, performing final notification sync...");
        final finalNotifications = await manager.retrieveNotifications(
          useChannel: channel,
        );
        await syncAndGetCount(currentEid, finalNotifications);
      } catch (e) {
        _log.warning("Final notification sync failed: $e");
      }
    } catch (e) {
      _log.severe("Error in background notification processing: $e");
    } finally {
      isProcessing.value = false;
    }
  }

  void togglePause() {
    isPaused.value = !isPaused.value;
    _pauseRequestedByUser = isPaused.value;
  }

  Future<void> _waitWhilePaused() async {
    while (isPaused.value) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  Future<NotificationSentResponse_deleteNotificationStatus?> _performRemoval(
    ProfileManager manager,
    Channel channel,
    int seqNumber,
  ) async {
    return await manager.removeNotification(seqNumber, useChannel: channel);
  }

  Future<int> syncAndGetCount(
    String eid,
    List<PendingNotification> notificationsOnCard,
  ) async {
    final seqNumbersOnCard = notificationsOnCard
        .map((n) => ProfileManager.extractMetadata(n)?.seqNumber)
        .whereType<int>()
        .toList();

    final db = await DatabaseService().database;
    if (seqNumbersOnCard.isEmpty) {
      // None on card, delete all unsent/failed ones for this EID
      await db.delete(
        'notifications',
        where: 'eid = ? AND status IN (0, 2)',
        whereArgs: [eid],
      );
    } else {
      // Delete unsent/failed ones for this EID that are NOT in the card list
      await db.delete(
        'notifications',
        where:
            'eid = ? AND status IN (0, 2) AND seqNumber NOT IN (${seqNumbersOnCard.join(",")})',
        whereArgs: [eid],
      );
    }

    // Calculate count of notifications on CURRENT card that are NOT sent
    final dbNotifs = await DatabaseService().getNotifications(eid);
    final unsentNotificationsOnCard = <PendingNotification>[];

    for (final n in notificationsOnCard) {
      final seq = ProfileManager.extractMetadata(n)?.seqNumber;
      if (seq == null) continue;

      bool alreadySent = false;
      for (final r in dbNotifs) {
        if (r.seqNumber == seq && r.status == 1) {
          // 1 is Sent
          alreadySent = true;
          break;
        }
      }

      if (!alreadySent) {
        unsentNotificationsOnCard.add(n);
      }
    }

    final unsentOnCard = unsentNotificationsOnCard.length;
    pendingCount.value = unsentOnCard;
    currentNotifications.value = unsentNotificationsOnCard;
    return unsentOnCard;
  }

  String? _getNotificationType(NotificationMetadata? metadata) {
    if (metadata == null) return null;

    final op = metadata.profileManagementOperation;
    int dataByte = op?.value ?? 0;

    if ((dataByte & NotificationEvent.notificationInstall) != 0) {
      return 'install';
    }
    if ((dataByte & NotificationEvent.notificationLocalEnable) != 0) {
      return 'enable';
    }
    if ((dataByte & NotificationEvent.notificationLocalDisable) != 0) {
      return 'disable';
    }
    if ((dataByte & NotificationEvent.notificationLocalDelete) != 0) {
      return 'delete';
    }
    if ((dataByte & NotificationEvent.notificationRpmEnable) != 0) {
      return 'rpm enable';
    }
    if ((dataByte & NotificationEvent.notificationRpmDisable) != 0) {
      return 'rpm disable';
    }
    if ((dataByte & NotificationEvent.notificationRpmDelete) != 0) {
      return 'rpm delete';
    }
    if ((dataByte & NotificationEvent.loadRpmPackageResult) != 0) {
      return 'load rpm';
    }

    return null;
  }
}
