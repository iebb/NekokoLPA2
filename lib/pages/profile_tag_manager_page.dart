import 'package:flutter/material.dart';
import '../services/profile_metadata_service.dart';
import '../utils/profile_tag_utils.dart';
import '../theme/app_theme.dart';
import '../widgets/styled_header_scaffold.dart';
import '../widgets/common/simple_dialog_container.dart';
import '../l10n/app_localizations.dart';
import '../services/tag_notification_service.dart';
import '../models/euicc_profile.dart';
import '../logic/profile_manager.dart';
import '../adapter/euicc_adapter.dart';

class ProfileTagManagerPage extends StatefulWidget {
  final EuiccProfile profile;
  final ProfileManager manager;
  final Reader reader;

  const ProfileTagManagerPage({
    super.key,
    required this.profile,
    required this.manager,
    required this.reader,
  });

  @override
  State<ProfileTagManagerPage> createState() => _ProfileTagManagerPageState();
}

class _ProfileTagManagerPageState extends State<ProfileTagManagerPage> {
  late List<ProfileTag> _tags;
  bool _isLoading = false;
  final TextEditingController _textTagController = TextEditingController();
  @override
  void initState() {
    super.initState();
    final parsed = ProfileTagUtils.parse(widget.profile.nickname);
    _tags = List.from(parsed.tags);
  }

  @override
  void dispose() {
    _textTagController.dispose();
    super.dispose();
  }

  Future<void> _saveTags() async {
    setState(() => _isLoading = true);
    try {
      final parsed = ProfileTagUtils.parse(widget.profile.nickname);
      final oldDateTag = parsed.tags.whereType<DateTag>().firstOrNull;
      final newDateTag = _tags.whereType<DateTag>().firstOrNull;

      final fullNickname = ProfileTagUtils.format(parsed.name, _tags);

      // Update the profile object locally to reflect changes immediately if passed by reference,
      // but primarily we send to modem.

      await widget.manager.adapter.connect(widget.reader);
      final channel = await widget.manager.openSession();
      try {
        await widget.manager.renameProfile(
          widget.profile.iccid,
          fullNickname,
          useChannel: channel,
        );

        if (mounted) {
          if (newDateTag != null) {
            if (oldDateTag == null) {
              await TagNotificationService().promptAndSchedule(
                context,
                widget.profile.iccid,
                newDateTag,
              );
            } else if (oldDateTag.raw != newDateTag.raw) {
              await TagNotificationService().promptAndReschedule(
                context,
                widget.profile.iccid,
                oldDateTag,
                newDateTag,
              );
            }
          } else if (oldDateTag != null) {
            await TagNotificationService().promptAndRemove(
              context,
              widget.profile.iccid,
              oldDateTag,
            );
          }
        }

        final metaService = await ProfileMetadataService.getInstance();
        await metaService.saveProfile(
          iccid: widget.profile.iccid,
          nickname: fullNickname,
          tags: _tags.map((t) => t.raw).toList(),
        );

        if (mounted) {
          Navigator.pop(context, true);
        }
      } finally {
        await channel.close();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${AppLocalizations.of(context)!.failedToSaveTags}: $e",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addTextTag() {
    final text = _textTagController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _tags.add(TextTag(text));
      _textTagController.clear();
    });
  }

  Future<void> _pickDateTag([DateTag? existingTag]) async {
    final DateTime initialDate =
        existingTag?.date ?? DateTime.now().add(const Duration(days: 30));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final noteController = TextEditingController(
        text: existingTag?.note ?? "",
      );
      final note = await showGeneralDialog<String>(
        context: context,
        barrierDismissible: true,
        barrierLabel: AppLocalizations.of(context)!.note,
        pageBuilder: (context, anim1, anim2) {
          return SimpleDialogContainer(
            title: AppLocalizations.of(context)!.addNoteOptional,
            primaryActionLabel: AppLocalizations.of(context)!.add,
            onPrimaryAction: () =>
                Navigator.pop(context, noteController.text.trim()),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: TextField(
                controller: noteController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.noteHint,
                  filled: true,
                ),
                autofocus: true,
              ),
            ),
          );
        },
      );

      if (mounted) {
        setState(() {
          // Replace existing date tag if any? Or allow multiple? Usually one expiration makes sense.
          // Requirement says "date tags are edited / found", implies one logic.
          _tags.removeWhere((t) => t is DateTag);
          _tags.add(
            DateTag(picked, note != null && note.isEmpty ? null : note),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StyledHeaderScaffold(
      title: AppLocalizations.of(context)!.manageTags,
      subtitle: widget.profile.displayName,
      actions: [
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveTags,
            tooltip: AppLocalizations.of(context)!.save,
          ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(AppLocalizations.of(context)!.activeTags),
            if (_tags.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.noTagsAssigned,
                    style: TextStyle(
                      color: AppTheme.onSurfaceVerySubtle(context),
                    ),
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) => _buildTagChip(tag)).toList(),
              ),
            const SizedBox(height: 32),
            _buildSectionHeader(AppLocalizations.of(context)!.addNewTag),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textTagController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.textTagHint,
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppTheme.surfaceSubtle(context),
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _addTextTag(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.add),
                  onPressed: _addTextTag,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _pickDateTag,
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(AppLocalizations.of(context)!.addDateExpiryTag),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: AppTheme.onSurfaceVerySubtle(context),
        ),
      ),
    );
  }

  Widget _buildTagChip(ProfileTag tag) {
    final theme = Theme.of(context);
    final isDate = tag is DateTag;
    final color = isDate
        ? theme.colorScheme.secondary
        : theme.colorScheme.primary;

    return InputChip(
      avatar: Icon(isDate ? Icons.event : Icons.label, size: 14, color: color),
      label: Text(
        isDate
            ? (tag).displayDate + (tag.note != null ? " (${tag.note})" : "")
            : (tag as TextTag).text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      onPressed: () {
        if (isDate) {
          _pickDateTag(tag); // This already handles replacing the old date tag
        } else {
          setState(() {
            _textTagController.text = (tag as TextTag).text;
            _tags.remove(tag);
          });
        }
      },
      onDeleted: () {
        setState(() {
          _tags.remove(tag);
        });
      },
      deleteIcon: const Icon(Icons.close, size: 14),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
