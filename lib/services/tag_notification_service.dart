import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import '../utils/profile_redaction.dart';
import '../utils/profile_tag_utils.dart';
import '../settings/app_settings.dart';
import '../widgets/common/simple_dialog_container.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class ScheduledNotification {
  final String text;
  final DateTime scheduledDate;
  final String iccid;
  final DateTime lastUpdated;
  final String? eid;

  ScheduledNotification({
    required this.text,
    required this.scheduledDate,
    required this.iccid,
    required this.lastUpdated,
    this.eid,
  });

  Map<String, dynamic> toMap() => {
    'text': text,
    'scheduledDate': _toMidnight(scheduledDate).millisecondsSinceEpoch,
    'iccid': iccid,
    'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    'eid': eid,
  };

  factory ScheduledNotification.fromMap(Map<String, dynamic> map) =>
      ScheduledNotification(
        text: map['text'] as String,
        scheduledDate: DateTime.fromMillisecondsSinceEpoch(
          map['scheduledDate'] as int,
        ),
        iccid: map['iccid'] as String,
        lastUpdated: DateTime.fromMillisecondsSinceEpoch(
          map['lastUpdated'] as int,
        ),
        eid: map['eid'] as String?,
      );

  static DateTime _toMidnight(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }
}

class TagNotificationService {
  static final TagNotificationService _instance =
      TagNotificationService._internal();
  factory TagNotificationService() => _instance;
  TagNotificationService._internal();

  static const String _tableName = 'scheduled_notifications';

  Future<void> upsertNotification(ScheduledNotification notif) async {
    final db = await DatabaseService().database;
    await db.insert(
      _tableName,
      notif.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteNotification(String text, DateTime date) async {
    final db = await DatabaseService().database;
    final midnight = DateTime(
      date.year,
      date.month,
      date.day,
    ).millisecondsSinceEpoch;
    await db.delete(
      _tableName,
      where: 'text = ? AND scheduledDate = ?',
      whereArgs: [text, midnight],
    );
  }

  Future<ScheduledNotification?> getNotification(
    String text,
    DateTime date,
  ) async {
    final db = await DatabaseService().database;
    final midnight = DateTime(
      date.year,
      date.month,
      date.day,
    ).millisecondsSinceEpoch;
    final results = await db.query(
      _tableName,
      where: 'text = ? AND scheduledDate = ?',
      whereArgs: [text, midnight],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return ScheduledNotification.fromMap(results.first);
  }

  Future<List<ScheduledNotification>> getAllNotifications() async {
    final db = await DatabaseService().database;
    final results = await db.query(_tableName, orderBy: 'scheduledDate ASC');
    return results.map((m) => ScheduledNotification.fromMap(m)).toList();
  }

  /// The `" for <name>"` suffix of the tag-change confirmations, with
  /// the nickname rules from [ProfileRedaction]: the nickname is
  /// suppressed entirely when the mode says so (falls back to the
  /// operator name), and a phone-like nickname is masked under
  /// full-hide or when the mode is redact-phone-numbers. Revealing
  /// shows the nickname as-is, like everywhere else.
  String _profileInfo({
    String? profileName,
    String? profileNickname,
    String? regionCode,
  }) {
    final settings = AppSettings();
    if (profileNickname != null &&
        profileNickname.isNotEmpty &&
        settings.nicknameRedactionMode !=
            NicknameRedactionMode.hideNickname) {
      final cleanedNickname = ProfileTagUtils.parse(
        profileNickname,
        regionCode: regionCode,
      ).displayName;
      if (cleanedNickname.isNotEmpty) {
        final shown =
            settings.revealSensitiveProfileData ||
                    (!settings.fullHideSensitiveData &&
                        settings.nicknameRedactionMode !=
                            NicknameRedactionMode.redactPhoneNumbers)
                ? cleanedNickname
                : ProfileRedaction.maskPhoneLike(cleanedNickname);
        if (shown.isNotEmpty) return ' for $shown';
      }
    }
    if (profileName != null && profileName.isNotEmpty) {
      return ' for $profileName';
    }
    return '';
  }

  Future<void> promptAndSchedule(
    BuildContext context,
    String iccid,
    DateTag tag, {
    String? profileName,
    String? profileNickname,
    String? regionCode,
  }) async {
    if (!AppSettings().enableScheduledNotifications) return;

    final tagLabel = tag.note ?? tag.raw;
    final existing = await getNotification(tagLabel, tag.date);
    if (existing != null) return; // Already scheduled for this text/date

    if (!context.mounted) return;

    // Use cleaned nickname (without tags) or fallback to name
    final profileInfo = _profileInfo(
      profileName: profileName,
      profileNickname: profileNickname,
      regionCode: regionCode,
    );

    // Display raw tag in quotes if no note
    final displayTag = tag.note ?? '"${tag.raw}"';

    final confirmed = await _showPrompt(
      context,
      "Schedule Reminder",
      "Would you like to schedule a notification for $displayTag$profileInfo on ${DateFormat('yyyy-MM-dd').format(tag.date.toLocal())}?",
    );

    if (confirmed == true) {
      if (context.mounted) {
        await _ensurePermissions(context);
      }

      await upsertNotification(
        ScheduledNotification(
          text: tagLabel,
          scheduledDate: tag.date,
          iccid: iccid,
          lastUpdated: DateTime.now(),
        ),
      );
    }
  }

  Future<void> promptAndReschedule(
    BuildContext context,
    String iccid,
    DateTag? oldTag,
    DateTag newTag, {
    String? profileName,
    String? profileNickname,
    String? regionCode,
  }) async {
    if (!AppSettings().enableScheduledNotifications) return;
    if (oldTag != null && oldTag.raw == newTag.raw) return;

    // Only prompt if there are scheduled ones for the old tag (per requirement)
    final oldTagLabel = oldTag?.note ?? oldTag?.raw ?? "Expiry";
    final existingOld = oldTag != null
        ? await getNotification(oldTagLabel, oldTag.date)
        : null;

    if (existingOld == null) {
      // If no old one, just offer to schedule the new one
      if (context.mounted) {
        await promptAndSchedule(
          context,
          iccid,
          newTag,
          profileName: profileName,
          profileNickname: profileNickname,
          regionCode: regionCode,
        );
      }
      return;
    }

    if (!context.mounted) return;

    // Use cleaned nickname (without tags) or fallback to name
    final profileInfo = _profileInfo(
      profileName: profileName,
      profileNickname: profileNickname,
      regionCode: regionCode,
    );

    // Display raw tag in quotes if no note
    final displayTag = newTag.note ?? '"${newTag.raw}"';
    final newTagLabel = newTag.note ?? newTag.raw;

    final confirmed = await _showPrompt(
      context,
      "Update Reminder",
      "The date tag has changed to $displayTag (${DateFormat('yyyy-MM-dd').format(newTag.date.toLocal())})$profileInfo. Would you like to update your scheduled reminder?",
    );

    if (confirmed == true) {
      if (context.mounted) {
        await _ensurePermissions(context);
      }

      await deleteNotification(oldTagLabel, oldTag!.date);
      await upsertNotification(
        ScheduledNotification(
          text: newTagLabel,
          scheduledDate: newTag.date,
          iccid: iccid,
          lastUpdated: DateTime.now(),
        ),
      );
    }
  }

  Future<void> promptAndRemove(
    BuildContext context,
    String iccid,
    DateTag tag, {
    String? profileName,
    String? profileNickname,
    String? regionCode,
  }) async {
    if (!AppSettings().enableScheduledNotifications) return;

    final tagLabel = tag.note ?? tag.raw;
    final existing = await getNotification(tagLabel, tag.date);
    if (existing == null) return;

    if (!context.mounted) return;

    // Use cleaned nickname (without tags) or fallback to name
    final profileInfo = _profileInfo(
      profileName: profileName,
      profileNickname: profileNickname,
      regionCode: regionCode,
    );

    // Display raw tag in quotes if no note
    final displayTag = tag.note ?? '"${tag.raw}"';

    final confirmed = await _showPrompt(
      context,
      "Remove Reminder",
      "The date tag $displayTag$profileInfo was removed. Would you like to also remove the scheduled notification?",
    );

    if (confirmed == true) {
      await deleteNotification(tagLabel, tag.date);
    }
  }

  Future<void> _ensurePermissions(BuildContext context) async {
    try {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        final result = await Permission.notification.request();
        if (!result.isGranted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                "Refused permissions to schedule notification.",
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              action: SnackBarAction(
                label: "Settings",
                onPressed: () => openAppSettings(),
                textColor: Colors.white,
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Silently ignore on unsupported platforms (Linux/macOS)
      debugPrint("Permission check not supported or failed: $e");
    }
  }

  Future<bool?> _showPrompt(
    BuildContext context,
    String title,
    String message,
  ) async {
    return await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return SimpleDialogContainer(
          title: title,
          primaryActionLabel: "Yes",
          secondaryActionLabel: "No",
          onPrimaryAction: () => Navigator.pop(context, true),
          onSecondaryAction: () => Navigator.pop(context, false),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.onSurfaceSubtle(context),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}
