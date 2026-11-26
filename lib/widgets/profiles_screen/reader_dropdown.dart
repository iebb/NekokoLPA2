import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../adapter/euicc_adapter.dart';
import '../../utils/profile_redaction.dart';
import '../common/reader_api_icon.dart';
import 'reader_helper.dart';

Widget buildReaderDropdown({
  required BuildContext context,
  required Reader? selectedReader,
  required List<Reader> readers,
  required bool showFullEid,
  void Function(Reader?)? onChanged,
  Function(Reader)? onRemove,
  VoidCallback? onOpen,
}) {
  final theme = Theme.of(context);

  return Container(
    width: double.infinity,
    height: 54,
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: theme.dividerColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: LayoutBuilder(
      builder: (context, c) {
        return Theme(
          data: theme.copyWith(
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: PopupMenuButton<Reader>(
            enabled: onChanged != null,
            initialValue: selectedReader,
            tooltip: "Select device",
            offset: const Offset(0, 58),
            constraints: BoxConstraints.tightFor(width: c.maxWidth),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.dividerColor),
            ),
            color: theme.colorScheme.surface,
            elevation: 8,
            onSelected: onChanged,
            child: GestureDetector(
              onLongPress: () {
                // Copy the raw EID: an explicit copy gesture copies the
                // real value (like the context-menu copy), never the
                // on-screen mask — under full-hide the redacted form
                // would otherwise land on the clipboard as `********`.
                final eid = selectedReader?.eid;
                if (eid != null && eid.isNotEmpty) {
                  Clipboard.setData(ClipboardData(text: eid));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('EID copied to clipboard'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    _getReaderIcon(selectedReader, context),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            selectedReader?.name ?? "Select Device",
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (selectedReader != null)
                            Flexible(
                              child: Text(
                                _formatReaderEid(
                                      selectedReader,
                                      showFullEid: showFullEid,
                                    ) ??
                                    "Unknown EID",
                                style: AppTheme.mono(
                                  TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.onSurfaceVerySubtle(
                                      context,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.unfold_more_rounded,
                      size: 18,
                      color: AppTheme.onSurfaceVerySubtle(context),
                    ),
                  ],
                ),
              ),
            ),
            itemBuilder: (context) {
              onOpen?.call();
              return readers.map((r) {
                final isSelected = r == selectedReader; // Uses Reader.==
                final isPersistent = ReaderHelper.isPersistent(r.id);

                return PopupMenuItem<Reader>(
                  value: r,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  )
                                : AppTheme.surfaceSubtle(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: _getReaderIcon(
                              r,
                              context,
                              size: 16,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                r.name,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSelected
                                      ? theme.colorScheme.onSurface
                                      : AppTheme.onSurfaceSubtle(context),
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _formatReaderEid(r, showFullEid: showFullEid) ??
                                    "Unknown EID",
                                style: AppTheme.mono(
                                  TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.onSurfaceVerySubtle(
                                      context,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          )
                        else if (isPersistent && onRemove != null)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              Navigator.pop(context); // Close menu
                              onRemove(r);
                            },
                            color: Colors.red.withValues(alpha: 0.7),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList();
            },
          ),
        );
      },
    ),
  );
}

Widget _getReaderIcon(
  Reader? reader,
  BuildContext context, {
  double size = 20,
  Color? color,
}) {
  final iconColor = ReaderHelper.getIconColor(
    reader?.id,
    context,
    overrideColor: color,
  );
  final apiIcon = ReaderApiIcon.forReaderId(
    reader?.id,
    context: context,
    size: size,
    color: iconColor,
  );
  if (apiIcon != null) return apiIcon;

  return Icon(
    ReaderHelper.getIconData(reader?.id),
    size: size,
    color: iconColor,
  );
}

String? _formatReaderEid(Reader? reader, {required bool showFullEid}) {
  if (reader == null) return null;

  final eid = reader.eid;

  if (eid == null || eid.isEmpty) return null;

  return ProfileRedaction.redactEid(eid, revealFull: showFullEid);
}
