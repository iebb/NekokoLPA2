import 'dart:convert';
import 'notification_processing_queue.dart';
import 'package:flutter/foundation.dart';
import '../models/asn1/rsp_definitions.g.dart';
import '../logic/profile_manager.dart';
import '../adapter/euicc_adapter.dart';
import '../adapter/se_hal_adapter.dart';
import '../utils/foreground_card_session.dart';
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
  NotificationService._internal()
    : _database = DatabaseService(),
      _sender = null;

  @visibleForTesting
  NotificationService.forTesting({
    required DatabaseService database,
    Future<SendResult> Function(PendingNotification, String)? sender,
  }) : _database = database,
       _sender = sender;

  final DatabaseService _database;
  final Future<SendResult> Function(PendingNotification, String)? _sender;
  final _queue = NotificationProcessingQueue();
  int _activeRuns = 0;
  String? currentEid;

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
    String address, {
    String? eid,
  }) async {
    final metadata = ProfileManager.extractMetadata(notification);
    final seq = metadata?.seqNumber;
    final iccid = metadata?.iccid == null
        ? 'Unknown'
        : HexUtils.swapNibbles(HexUtils.bytesToHex(metadata!.iccid!));
    final content = base64Encode(notification.encode());
    if (eid != null &&
        seq != null &&
        await _database.isNotificationSent(eid, seq, iccid, content: content)) {
      return true;
    }
    final result = await sendNotificationRaw(notification, address);
    if (eid != null && seq != null) {
      await _database.saveNotification(
        NotificationRecord(
          eid: eid,
          iccid: iccid,
          seqNumber: seq,
          content: content,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          status: result.success ? 1 : 2,
          responseCode: result.statusCode,
          responseContent: result.body,
          notificationServer: address,
          notificationType: _getNotificationType(metadata),
        ),
      );
      if (result.success) {
        currentEid = eid;
        sentSeq.value = null;
        sentSeq.value = seq;
      }
    }
    return result.success;
  }

  Future<SendResult> sendNotificationRaw(
    PendingNotification notification,
    String address,
  ) async {
    if (address.isEmpty) return SendResult(false, 0, "Empty address");
    if (_sender != null) return _sender(notification, address);

    try {
      final data = await SmdpClient.post(
        smdpAddress: address,
        endpoint: 'handleNotification',
        bodyData: {'pendingNotification': base64Encode(notification.encode())},
      );
      // HTTP errors and explicit SM-DP+ execution failures are not delivered.
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
    if (channel == null) {
      await _queue.run(
        () => _processRequest(
          manager,
          null,
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
        ),
      );
    } else {
      await _processRequest(
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
  }

  Future<void> _processRequest(
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
    if (channel == null && ForegroundCardSession.isOpen) return;
    _activeRuns++;
    isProcessing.value = true;
    try {
      // Use adapter.runExclusive (if Ccid) or just ensure single channel.
      // We'll wrap the whole flow in a single session if channel is null.
      if (channel == null) {
        await manager.adapter.runExclusive(() async {
          if (readerName != null &&
              manager.adapter.connectedReader?.id != readerName) {
            return;
          }
          if (ForegroundCardSession.isOpen) return;
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
      _activeRuns--;
      isProcessing.value = _activeRuns != 0;
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
      final currentEid = await manager.getEid(useChannel: channel);
      if (eid != null &&
          eid != 'Unknown' &&
          currentEid.toLowerCase() != eid.toLowerCase()) {
        _log.info('Skipping notification request for a card that has changed');
        return;
      }
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
        final pendingDeletes = await _database.getDeletePendingNotifications(
          currentEid,
        );
        for (final p in halSendOnly ? <NotificationRecord>[] : pendingDeletes) {
          seqsToRemove.add(p.seqNumber);
          seqToIccid[p.seqNumber] = p.iccid;
        }
      } catch (e) {
        _log.warning("Error collecting pending deletes: $e");
      }

      final jobsByRsp = <String, List<PendingNotification>>{};

      for (var n in notifications) {
        var metadata = ProfileManager.extractMetadata(n);
        if (metadata == null) continue;

        var iccid = metadata.iccid != null
            ? HexUtils.swapNibbles(HexUtils.bytesToHex(metadata.iccid!))
            : "Unknown";
        var seq = metadata.seqNumber ?? -1;

        // Ensure resolution and backup
        final existing = await _database.getNotification(
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
          metadata = ProfileManager.extractMetadata(n) ?? metadata;
          iccid = metadata.iccid != null
              ? HexUtils.swapNibbles(HexUtils.bytesToHex(metadata.iccid!))
              : iccid;
          seq = metadata.seqNumber ?? seq;
          if (await _database.isNotificationSent(
            currentEid,
            seq,
            iccid,
            content: base64Encode(n.encode()),
          )) {
            processedAsSent.add(seq);
          }
          // Backup only an unsent payload. Deleting history must stay deleted.
          if (!processedAsSent.contains(seq)) {
            _log.info("Backing up notification: seq=$seq iccid=$iccid");
            await _database.saveNotification(
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
          }
        } else if (n.asn1 == null) {
          // Skeleton from card but we HAVE backup in DB -> Resolve from DB
          _log.info("Restoring notification from local backup: seq=$seq");
          n = PendingNotification.decode(base64Decode(existing.content));
          metadata = ProfileManager.extractMetadata(n) ?? metadata;
          iccid = metadata.iccid != null
              ? HexUtils.swapNibbles(HexUtils.bytesToHex(metadata.iccid!))
              : iccid;
          seq = metadata.seqNumber ?? seq;
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
          await _database.updateNotificationStatus(
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
          final isSent = await _database.isNotificationSent(
            currentEid,
            seq,
            iccid,
            content: base64Encode(n.encode()),
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
                await _database.saveNotification(
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
                await _database.updateNotificationStatus(
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

            await _performRemoval(manager, activeChannel, seq);
            final iccid = seqToIccid[seq] ?? "Unknown";
            await _database.setDeletePending(currentEid, seq, iccid, false);

            if (!processedAsSent.contains(seq)) {
              if (pendingCount.value > 0) pendingCount.value--;
            }
            removedSeq.value = seq;
          } catch (e) {
            _log.severe("Failed to remove notification $seq: $e");
            final iccid = seqToIccid[seq] ?? "Unknown";
            await _database.setDeletePending(currentEid, seq, iccid, true);
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

  Future<List<PendingNotification>> _performRemoval(
    ProfileManager manager,
    Channel channel,
    int seqNumber,
  ) async {
    final status = await manager.removeNotification(
      seqNumber,
      useChannel: channel,
    );
    if (status != NotificationSentResponse_deleteNotificationStatus.ok &&
        status !=
            NotificationSentResponse_deleteNotificationStatus.nothingToDelete) {
      throw StateError('Notification removal failed (${status?.value})');
    }
    final remaining = await manager.retrieveNotifications(useChannel: channel);
    if (remaining.any(
      (n) => ProfileManager.extractMetadata(n)?.seqNumber == seqNumber,
    )) {
      throw StateError('Notification removal was not confirmed by the card');
    }
    return remaining;
  }

  Future<int> syncAndGetCount(
    String eid,
    List<PendingNotification> notificationsOnCard,
  ) async {
    final seqNumbersOnCard = notificationsOnCard
        .map((n) => ProfileManager.extractMetadata(n)?.seqNumber)
        .whereType<int>()
        .toList();

    final db = await _database.database;
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

    final sent = await _database.getSentNotificationSequences(eid);
    final unsentOnCard = notificationsOnCard
        .where(
          (n) => !sent.contains(ProfileManager.extractMetadata(n)?.seqNumber),
        )
        .length;
    currentEid = eid;
    pendingCount.value = unsentOnCard;
    currentNotifications.value = List.unmodifiable(notificationsOnCard);
    return unsentOnCard;
  }

  /// Removing a retained card entry is independent of sending it to SM-DP+.
  Future<void> removeFromCard(
    ProfileManager manager,
    Channel channel,
    int seq, {
    String? expectedEid,
  }) async {
    final eid = await manager.getEid(useChannel: channel);
    if (expectedEid != null && eid.toLowerCase() != expectedEid.toLowerCase()) {
      throw StateError(
        'The selected eUICC changed before notification removal',
      );
    }
    final remaining = await _performRemoval(manager, channel, seq);
    await syncAndGetCount(eid, remaining);
    removedSeq.value = seq;
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
