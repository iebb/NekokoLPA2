import 'package:flutter/material.dart';

import '../../settings/app_settings.dart';
import '../../theme/app_theme.dart';
import '../../utils/profile_redaction.dart';
import '../../widgets/styled_header_scaffold.dart';

class RedactionSettingsPage extends StatelessWidget {
  const RedactionSettingsPage({super.key});

  static const String _sampleEid = '8904903200000000000000001234567890';
  static const String _sampleIccid = '89882810345678901234';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings(),
      builder: (context, _) {
        return StyledHeaderScaffold(
          title: 'Redaction',
          subtitle: 'Control what the app reveals on screen',
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSection(
                context,
                title: 'Identifiers',
                children: [
                  _buildSegmentPreviewTile(
                    context,
                    title: 'EID',
                    preview: ProfileRedaction.redactEidPreview(_sampleEid),
                    toggles: [
                      _SegmentToggle(
                        label: 'First 8',
                        value: AppSettings().redactEidFirst,
                        onChanged: AppSettings().setRedactEidFirst,
                      ),
                      _SegmentToggle(
                        label: 'Mid 22',
                        value: AppSettings().redactEidMiddle,
                        onChanged: AppSettings().setRedactEidMiddle,
                      ),
                      _SegmentToggle(
                        label: 'Last 2',
                        value: AppSettings().redactEidLast,
                        onChanged: AppSettings().setRedactEidLast,
                      ),
                    ],
                  ),
                  _buildSegmentPreviewTile(
                    context,
                    title: 'ICCID',
                    preview: ProfileRedaction.redactIccidPreview(_sampleIccid),
                    toggles: [
                      _SegmentToggle(
                        label: 'First 8',
                        value: AppSettings().redactIccidFirst,
                        onChanged: AppSettings().setRedactIccidFirst,
                      ),
                      _SegmentToggle(
                        label: 'Mid 6',
                        value: AppSettings().redactIccidMiddle,
                        onChanged: AppSettings().setRedactIccidMiddle,
                      ),
                      _SegmentToggle(
                        label: 'Last 6',
                        value: AppSettings().redactIccidLast,
                        onChanged: AppSettings().setRedactIccidLast,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                title: 'Profile Content',
                children: [
                  _buildDropdownTile<FlagRedactionMode>(
                    context,
                    title: 'Fake Profile',
                    value: AppSettings().flagRedactionMode,
                    items: const {
                      FlagRedactionMode.none: 'No redaction',
                      FlagRedactionMode.shuffledFlags: 'Use fake local profile',
                    },
                    onChanged: AppSettings().setFlagRedactionMode,
                  ),
                  _buildDropdownTile<NicknameRedactionMode>(
                    context,
                    title: 'Nickname',
                    value: AppSettings().nicknameRedactionMode,
                    items: const {
                      NicknameRedactionMode.none: 'No redaction',
                      NicknameRedactionMode.redactPhoneNumbers:
                          'Redact phone numbers',
                      NicknameRedactionMode.hideNickname: "Don't show nickname",
                    },
                    onChanged: AppSettings().setNicknameRedactionMode,
                  ),
                  _buildDropdownTile<OperatorRedactionMode>(
                    context,
                    title: 'Redact Carrier',
                    value: AppSettings().operatorRedactionMode,
                    items: const {
                      OperatorRedactionMode.none: 'No redaction',
                      OperatorRedactionMode.countryName: 'Display country only',
                    },
                    onChanged: AppSettings().setOperatorRedactionMode,
                  ),
                  _buildDropdownTile<TagsRedactionMode>(
                    context,
                    title: 'Tags',
                    value: AppSettings().tagsRedactionMode,
                    items: const {
                      TagsRedactionMode.none: 'No redaction',
                      TagsRedactionMode.hideTags: 'Hide tags',
                    },
                    onChanged: AppSettings().setTagsRedactionMode,
                  ),
                  _buildDropdownTile<IconRedactionMode>(
                    context,
                    title: 'Icon',
                    value: AppSettings().iconRedactionMode,
                    items: const {
                      IconRedactionMode.none: 'No redaction',
                      IconRedactionMode.hideIcon: 'Hide icon',
                      IconRedactionMode.randomIcon: 'Use random icon',
                    },
                    onChanged: AppSettings().setIconRedactionMode,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
              letterSpacing: 2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  RepaintBoundary(child: children[i]),
                  if (i < children.length - 1)
                    Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: theme.dividerColor.withValues(alpha: 0.08),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentPreviewTile(
    BuildContext context, {
    required String title,
    required String preview,
    required List<_SegmentToggle> toggles,
  }) {
    final theme = Theme.of(context);
    final compact = MediaQuery.of(context).size.width < 420;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            preview,
            maxLines: compact ? 2 : 1,
            overflow: TextOverflow.fade,
            style: TextStyle(
              fontSize: compact ? 11.5 : 12.5,
              fontFamily: 'monospace',
              color: AppTheme.onSurfaceSubtle(context),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          _buildGroupedToggles(context, toggles, compact),
        ],
      ),
    );
  }

  Widget _buildGroupedToggles(
    BuildContext context,
    List<_SegmentToggle> toggles,
    bool compact,
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.28,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < toggles.length; i++) ...[
            Expanded(
              child: _buildGroupedToggleButton(
                context,
                toggle: toggles[i],
                compact: compact,
                isFirst: i == 0,
                isLast: i == toggles.length - 1,
              ),
            ),
            if (i < toggles.length - 1)
              Container(
                width: 1,
                height: compact ? 34 : 38,
                color: theme.dividerColor.withValues(alpha: 0.5),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupedToggleButton(
    BuildContext context, {
    required _SegmentToggle toggle,
    required bool compact,
    required bool isFirst,
    required bool isLast,
  }) {
    final theme = Theme.of(context);
    final selected = toggle.value;

    return Material(
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.14)
          : Colors.transparent,
      borderRadius: BorderRadius.horizontal(
        left: isFirst ? const Radius.circular(13) : Radius.zero,
        right: isLast ? const Radius.circular(13) : Radius.zero,
      ),
      child: InkWell(
        borderRadius: BorderRadius.horizontal(
          left: isFirst ? const Radius.circular(13) : Radius.zero,
          right: isLast ? const Radius.circular(13) : Radius.zero,
        ),
        onTap: () => toggle.onChanged(!toggle.value),
        child: Container(
          alignment: Alignment.center,
          constraints: BoxConstraints(minHeight: compact ? 34 : 38),
          padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
          child: Text(
            toggle.label,
            style: TextStyle(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownTile<T>(
    BuildContext context, {
    required String title,
    required T value,
    required Map<T, String> items,
    required Future<void> Function(T value) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  items[value] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.onSurfaceSubtle(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildAdaptiveDropdown(
            context: context,
            value: value,
            items: items.entries
                .map(
                  (entry) => DropdownMenuItem<T>(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
            onChanged: (next) {
              if (next != null) {
                onChanged(next);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptiveDropdown<T>({
    required BuildContext context,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
  }) {
    final theme = Theme.of(context);
    final currentItem = items.firstWhere(
      (item) => item.value == value,
      orElse: () => items.first,
    );

    return Theme(
      data: theme.copyWith(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: PopupMenuButton<T>(
        initialValue: currentItem.value,
        offset: const Offset(0, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.dividerColor),
        ),
        color: theme.colorScheme.surface,
        elevation: 8,
        onSelected: onChanged,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  child: currentItem.child,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppTheme.onSurfaceVerySubtle(context),
              ),
            ],
          ),
        ),
        itemBuilder: (context) {
          return items.map((item) {
            final isSelected = item.value == currentItem.value;
            return PopupMenuItem<T>(
              value: item.value,
              child: Row(
                children: [
                  Expanded(
                    child: DefaultTextStyle.merge(
                      style: TextStyle(
                        color: isSelected
                            ? theme.colorScheme.onSurface
                            : AppTheme.onSurfaceSubtle(context),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 14,
                      ),
                      child: item.child,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
            );
          }).toList();
        },
      ),
    );
  }
}

class _SegmentToggle {
  final String label;
  final bool value;
  final Future<void> Function(bool value) onChanged;

  const _SegmentToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });
}
