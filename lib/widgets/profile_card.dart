import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../utils/profile_tag_utils.dart';
import '../models/euicc_profile.dart';
import '../settings/app_settings.dart';
import '../utils/iccid_formatter.dart';
import '../services/database_service.dart';
import '../services/operator_icon_service.dart';
import '../utils/size_formatter.dart';
import 'common/loading_spinner.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/profile_size_prediction_service.dart';
import '../plugins/plugin_manager.dart';
import 'profile_card_bottom.dart';
import '../utils/profile_redaction.dart';

class _Base64ImageCache {
  static const int _maxEntries = 128;
  static final Map<String, Uint8List> _cache = {};

  static Uint8List? decode(String encoded) {
    final cached = _cache[encoded];
    if (cached != null) return cached;
    try {
      final bytes = base64Decode(encoded);
      if (_cache.length >= _maxEntries) {
        _cache.remove(_cache.keys.first);
      }
      _cache[encoded] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }
}

class ProfileCard extends StatelessWidget {
  final EuiccProfile profile;
  final bool isToggling;
  final bool isDeleting;
  final bool isLocked;
  final bool isCompact;
  final Function(bool) onToggle;
  final VoidCallback? onMenu;
  final VoidCallback? onTagTap;
  final String? eid; // Add EID to look up storage
  final GlobalKey? cardKey;

  const ProfileCard({
    super.key,
    required this.profile,
    required this.onToggle,
    this.onMenu,
    this.onTagTap,
    this.eid,
    this.cardKey,
    this.isToggling = false,
    this.isDeleting = false,
    this.isLocked = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = ProfileRedaction.displayName(profile);
    final displayIccid = ProfileRedaction.redactIccid(profile.iccid);
    final displayTags = ProfileRedaction.tags(profile.tags);
    final operatorSummary = ProfileRedaction.operatorSummary(profile);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.highlightedCardDecoration(
        context,
        enabled: profile.enabled,
      ),
      child: AnimatedScale(
        scale: isDeleting ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: AnimatedOpacity(
          opacity: isDeleting ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ExcludeSemantics(
              child: Material(
                key: cardKey,
                color: Colors.transparent,
                child: InkWell(
                  onTap: onMenu,
                  onLongPress: onMenu,
                  onSecondaryTap: onMenu,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                            child: Row(
                              children: [
                                ProfileIcon(
                                  profile: profile,
                                  isCompact: isCompact,
                                ),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          _buildFlagWidget(theme),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              displayName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: isCompact ? 14 : 16,
                                                color:
                                                    theme.colorScheme.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (profile.profileClass == 0) ...[
                                            const SizedBox(width: 6),
                                            _buildClassBadge(
                                              'TEST',
                                              Colors.blue,
                                              theme,
                                            ),
                                          ],
                                          if (profile.profileClass == 1) ...[
                                            const SizedBox(width: 6),
                                            _buildClassBadge(
                                              'PROV',
                                              Colors.orange,
                                              theme,
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        IccidFormatter.forDisplay(displayIccid),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.5),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (operatorSummary != null &&
                                          operatorSummary.isNotEmpty) ...[
                                        const SizedBox(height: 1),
                                        Text(
                                          operatorSummary,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],

                                      if (displayTags.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        _buildTagsSection(
                                          context,
                                          theme,
                                          displayTags,
                                        ),
                                      ],

                                      ...PluginManager().buildProfileCardExtras(
                                        context,
                                        profile,
                                      ),
                                    ],
                                  ),
                                ), // Column
                                const SizedBox(width: 8),

                                // Toggle Switch
                                _buildToggle(theme),
                              ],
                            ),
                          ),

                          if (isDeleting)
                            Positioned.fill(
                              child: Container(
                                color: theme.colorScheme.surface.withValues(
                                  alpha: 0.4,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      LoadingSpinner(
                                        size: 24,
                                        strokeWidth: 3,
                                        color: theme.colorScheme.error,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        AppLocalizations.of(context)!.deleting,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // Absolute Positioned Storage Badge
                          if (eid != null)
                            Positioned(
                              bottom: 2,
                              right: 16,
                              child: ProfileSizeBadge(
                                eid: eid!,
                                profile: profile,
                                theme: theme,
                              ),
                            ),
                        ],
                      ),
                      Builder(
                        builder: (context) {
                          final bottomData = PluginManager()
                              .getMergedProfileCardBottomData(profile);
                          if (bottomData != null && !bottomData.isEmpty) {
                            return ProfileCardBottom(
                              themeColor: bottomData.themeColor,
                              phoneNumber: bottomData.phoneNumber,
                              lineExpiry: bottomData.lineExpiry,
                              balance: bottomData.balance,
                              packages: bottomData.packages,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassBadge(String label, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTagsSection(
    BuildContext context,
    ThemeData theme,
    List<String> tags,
  ) {
    return GestureDetector(
      onTap: onTagTap,
      behavior: HitTestBehavior.opaque,
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: tags.map((tagStr) {
          final tag = ProfileTag.parse(tagStr);
          return _buildTagChip(tag, theme, context);
        }).toList(),
      ),
    );
  }

  Widget _buildFlagWidget(ThemeData theme) {
    final width = isCompact ? 20.0 : 24.0;
    final height = isCompact ? 14.0 : 16.0;
    final radius = BorderRadius.circular(2);

    if (ProfileRedaction.hideFlag) {
      return Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: radius,
          color: theme.colorScheme.surfaceContainerHighest,
        ),
        child: Icon(
          Icons.flag_outlined,
          size: isCompact ? 12 : 14,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: CachedNetworkImage(
          imageUrl: ProfileRedaction.flagUrl(profile),
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => Icon(
            Icons.flag_outlined,
            size: isCompact ? 12 : 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildTagChip(ProfileTag tag, ThemeData theme, BuildContext context) {
    if (tag is DateTag) {
      final countdown = tag.countdown;
      final isExpired = countdown.isNegative;
      final color = isExpired ? Colors.red : theme.colorScheme.secondary;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 10, color: color),
            const SizedBox(width: 4),
            Text(
              tag.displayDate,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              _formatCountdown(context, countdown),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color.withValues(alpha: 0.8),
              ),
            ),
            if (tag.note != null) ...[
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  tag.note!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      );
    } else if (tag is TextTag) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Text(
          tag.text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.primary,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  String _formatCountdown(BuildContext context, Duration d) {
    if (d.isNegative) return AppLocalizations.of(context)!.expired;
    if (d.inDays > 0) return "${d.inDays}d";
    if (d.inHours > 0) return "${d.inHours}h";
    if (d.inMinutes > 0) return "${d.inMinutes}m";
    return AppLocalizations.of(context)!.soon;
  }

  Widget _buildToggle(ThemeData theme) {
    final bool effectivelyLocked = isToggling || isLocked;
    return GestureDetector(
      onTap: effectivelyLocked ? null : () => onToggle(!profile.enabled),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 50,
        height: 28,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: effectivelyLocked
              ? theme.colorScheme.onSurface.withValues(alpha: 0.1)
              : (profile.enabled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.2)),
        ),
        child: isToggling
            ? Center(
                child: LoadingSpinner(
                  size: 18,
                  strokeWidth: 2.5,
                  color: theme.colorScheme.primary,
                ),
              )
            : AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: profile.enabled
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class ProfileIcon extends StatelessWidget {
  final EuiccProfile profile;
  final bool isCompact;

  const ProfileIcon({
    super.key,
    required this.profile,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = AppSettings();
    final size = isCompact ? 40.0 : 48.0;
    final margin = EdgeInsets.only(right: isCompact ? 12 : 16);
    final radius = isCompact ? 10.0 : 12.0;

    if (ProfileRedaction.hideIcon) {
      return Container(width: size, height: size, margin: margin);
    }
    if (ProfileRedaction.randomIcon) {
      return _buildRandomizedIcon(theme, size, margin, radius);
    }

    final hasProfileIcon = profile.icon != null;
    final loadProfileIcons = settings.loadProfileIcons;
    final useNekokoIcons = settings.useNekokoIcons;

    // Priority 1: Custom Icon (User-selected from gallery)
    if (profile.customIcon != null && profile.customIcon!.isNotEmpty) {
      final imageBytes = _Base64ImageCache.decode(profile.customIcon!);
      if (imageBytes != null) {
        return Container(
          width: size,
          height: size,
          margin: margin,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image.memory(
              imageBytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              cacheWidth: (size * 2).toInt(),
              errorBuilder: (context, error, stackTrace) =>
                  _buildFallbackProfileIcon(
                    theme,
                    isCompact,
                    loadProfileIcons,
                    hasProfileIcon,
                    size,
                    margin,
                    radius,
                    useNekokoIcons,
                  ),
            ),
          ),
        );
      }
    }

    // Priority 2: Large profile icon from card
    bool preferProfileIcon = false;
    if (loadProfileIcons && hasProfileIcon) {
      if (profile.icon!.lengthInBytes >= 2048) {
        preferProfileIcon = true;
      }
    }

    if (preferProfileIcon) {
      return Container(
        width: size,
        height: size,
        margin: margin,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.memory(
            profile.icon!,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            cacheWidth: (size * 2).toInt(),
            errorBuilder: (context, error, stackTrace) {
              if (useNekokoIcons &&
                  profile.mcc != null &&
                  profile.mnc != null) {
                return _buildNekokoIcon(
                  theme,
                  size,
                  margin,
                  radius,
                  isCompact,
                  loadProfileIcons,
                  hasProfileIcon,
                  useNekokoIcons,
                );
              }
              return _buildPlaceholderIcon(theme, isCompact);
            },
          ),
        ),
      );
    }

    if (useNekokoIcons && profile.mcc != null && profile.mnc != null) {
      return _buildNekokoIcon(
        theme,
        size,
        margin,
        radius,
        isCompact,
        loadProfileIcons,
        hasProfileIcon,
        useNekokoIcons,
      );
    }

    return _buildFallbackProfileIcon(
      theme,
      isCompact,
      loadProfileIcons,
      hasProfileIcon,
      size,
      margin,
      radius,
      useNekokoIcons,
    );
  }

  Widget _buildNekokoIcon(
    ThemeData theme,
    double size,
    EdgeInsets margin,
    double radius,
    bool isCompact,
    bool loadProfileIcons,
    bool hasProfileIcon,
    bool useNekokoIcons,
  ) {
    return ValueListenableBuilder<int>(
      valueListenable: OperatorIconService().iconUpdateNotifier,
      builder: (context, _, child) {
        final cachedIcon = OperatorIconService().getIconFromMemory(
          mcc: profile.mcc!,
          mnc: profile.mnc!,
          gid1: profile.gid1,
          gid2: profile.gid2,
        );

        if (cachedIcon != null && cachedIcon.isNotEmpty) {
          final imageBytes = OperatorIconService()
              .getDecodedIconBytesFromMemory(
                mcc: profile.mcc!,
                mnc: profile.mnc!,
                gid1: profile.gid1,
                gid2: profile.gid2,
              );
          if (imageBytes != null) {
            return Container(
              width: size,
              height: size,
              margin: margin,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(radius),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: Image.memory(
                  imageBytes,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  cacheWidth: (size * 2).toInt(),
                  errorBuilder: (context, error, stackTrace) =>
                      _buildFallbackProfileIcon(
                        theme,
                        isCompact,
                        loadProfileIcons,
                        hasProfileIcon,
                        size,
                        margin,
                        radius,
                        useNekokoIcons,
                      ),
                ),
              ),
            );
          }
          return _buildFallbackProfileIcon(
            theme,
            isCompact,
            loadProfileIcons,
            hasProfileIcon,
            size,
            margin,
            radius,
            useNekokoIcons,
          );
        }

        if (OperatorIconService().hasCachedIcon(
          mcc: profile.mcc!,
          mnc: profile.mnc!,
          gid1: profile.gid1,
          gid2: profile.gid2,
        )) {
          return _buildFallbackProfileIcon(
            theme,
            isCompact,
            loadProfileIcons,
            hasProfileIcon,
            size,
            margin,
            radius,
            useNekokoIcons,
          );
        }

        return FutureBuilder<String?>(
          future: OperatorIconService().getIcon(
            mcc: profile.mcc!,
            mnc: profile.mnc!,
            gid1: profile.gid1,
            gid2: profile.gid2,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasData &&
                  snapshot.data != null &&
                  snapshot.data!.isNotEmpty) {
                final imageBytes = _Base64ImageCache.decode(snapshot.data!);
                if (imageBytes != null) {
                  return Container(
                    width: size,
                    height: size,
                    margin: margin,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(radius),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      child: Image.memory(
                        imageBytes,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        cacheWidth: (size * 2).toInt(),
                        errorBuilder: (context, error, stackTrace) =>
                            _buildFallbackProfileIcon(
                              theme,
                              isCompact,
                              loadProfileIcons,
                              hasProfileIcon,
                              size,
                              margin,
                              radius,
                              useNekokoIcons,
                            ),
                      ),
                    ),
                  );
                }
                return _buildFallbackProfileIcon(
                  theme,
                  isCompact,
                  loadProfileIcons,
                  hasProfileIcon,
                  size,
                  margin,
                  radius,
                  useNekokoIcons,
                );
              }
              return _buildFallbackProfileIcon(
                theme,
                isCompact,
                loadProfileIcons,
                hasProfileIcon,
                size,
                margin,
                radius,
                useNekokoIcons,
              );
            }

            return _buildFallbackProfileIcon(
              theme,
              isCompact,
              loadProfileIcons,
              hasProfileIcon,
              size,
              margin,
              radius,
              useNekokoIcons,
            );
          },
        );
      },
    );
  }

  Widget _buildFallbackProfileIcon(
    ThemeData theme,
    bool isCompact,
    bool loadProfileIcons,
    bool hasProfileIcon,
    double size,
    EdgeInsets margin,
    double radius,
    bool useNekokoIcons,
  ) {
    if (loadProfileIcons && hasProfileIcon) {
      return Container(
        width: size,
        height: size,
        margin: margin,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.memory(
            profile.icon!,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            cacheWidth: (size * 2).toInt(),
          ),
        ),
      );
    }

    if (loadProfileIcons || useNekokoIcons) {
      return _buildPlaceholderIcon(theme, isCompact);
    }

    return const SizedBox.shrink();
  }

  Widget _buildPlaceholderIcon(ThemeData theme, bool isCompact) {
    final size = isCompact ? 40.0 : 48.0;
    final margin = EdgeInsets.only(right: isCompact ? 12 : 16);
    final radius = isCompact ? 10.0 : 12.0;

    return Container(
      width: size,
      height: size,
      margin: margin,
      decoration: BoxDecoration(
        color: profile.enabled
            ? theme.colorScheme.primary.withValues(alpha: 0.2)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        Icons.sim_card_outlined,
        color: profile.enabled
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.4),
        size: isCompact ? 20 : 24,
      ),
    );
  }

  Widget _buildRandomizedIcon(
    ThemeData theme,
    double size,
    EdgeInsets margin,
    double radius,
  ) {
    const icons = <IconData>[
      Icons.sim_card_outlined,
      Icons.bolt_outlined,
      Icons.public_outlined,
      Icons.network_cell_outlined,
      Icons.shield_outlined,
      Icons.language_outlined,
    ];
    const colors = <Color>[
      Colors.blue,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.green,
      Colors.indigo,
    ];

    final iconIndex = ProfileRedaction.stableIndex(profile.iccid, icons.length);
    final colorIndex = ProfileRedaction.stableIndex(
      '${profile.iccid}:color',
      colors.length,
    );
    final color = colors[colorIndex];

    return Container(
      width: size,
      height: size,
      margin: margin,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icons[iconIndex], color: color, size: isCompact ? 20 : 24),
    );
  }
}

class ProfileSizeBadge extends StatelessWidget {
  final String eid;
  final EuiccProfile profile;
  final ThemeData theme;

  const ProfileSizeBadge({
    super.key,
    required this.eid,
    required this.profile,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final database = DatabaseService();
    if (database.hasCachedProfileSize(eid, profile.iccid)) {
      return _buildSizeOrPrediction(
        context,
        database.getProfileSizeSync(eid, profile.iccid),
      );
    }
    return FutureBuilder<int?>(
      future: database.getProfileSize(eid, profile.iccid),
      builder: (context, snapshot) =>
          _buildSizeOrPrediction(context, snapshot.data),
    );
  }

  Widget _buildSizeOrPrediction(BuildContext context, int? size) {
    if (size != null && size > 0) return _buildSizeBadge(size, theme);
    if (!AppSettings().estimateProfileSize) return const SizedBox.shrink();
    final predictions = ProfileSizePredictionService();
    predictions.ensureLoaded();
    return ListenableBuilder(
      listenable: predictions,
      builder: (context, _) {
        final predicted = predictions.predictSize(
          eid: eid,
          smdpAddress: profile.smdpAddress,
          plmn: profile.mcc != null && profile.mnc != null
              ? '${profile.mcc}${profile.mnc}'
              : null,
          serviceProviderName: profile.serviceProviderName,
        );
        return predicted != null && predicted > 0
            ? _buildEstimatedSizeBadge(predicted, theme)
            : const SizedBox.shrink();
      },
    );
  }

  Widget _buildSizeBadge(int size, ThemeData theme) {
    final sizeStr = SizeFormatter.format(size);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.storage_rounded,
          size: 10,
          color: theme.colorScheme.tertiary,
        ),
        const SizedBox(width: 4),
        Text(
          sizeStr,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildEstimatedSizeBadge(int size, ThemeData theme) {
    final sizeStr = "~${SizeFormatter.format(size, precision: 0)}";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 10,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            sizeStr,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
