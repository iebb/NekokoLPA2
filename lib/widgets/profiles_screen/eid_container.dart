import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/asn1/rsp_definitions.g.dart';
import '../../utils/size_formatter.dart';
import '../../utils/profile_redaction.dart';

class EidContainer extends StatefulWidget {
  final String? eid;
  final String? status;
  final ExtendedCardResource? extCardResource;
  final bool showFullEid;
  final VoidCallback onToggleEidVisibility;
  final Function(GlobalKey anchorKey) onContextMenu;

  const EidContainer({
    super.key,
    this.eid,
    this.status,
    this.extCardResource,
    required this.showFullEid,
    required this.onToggleEidVisibility,
    required this.onContextMenu,
  });

  @override
  State<EidContainer> createState() => _EidContainerState();
}

class _EidContainerState extends State<EidContainer> {
  // Held in the State: as a field of the widget it was a new key on every
  // parent rebuild, which tore down and rebuilt the whole subtree each time.
  final GlobalKey _eidKey = GlobalKey();

  String? get eid => widget.eid;
  String? get status => widget.status;
  ExtendedCardResource? get extCardResource => widget.extCardResource;
  bool get showFullEid => widget.showFullEid;
  VoidCallback get onToggleEidVisibility => widget.onToggleEidVisibility;
  Function(GlobalKey anchorKey) get onContextMenu => widget.onContextMenu;

  String _maskEid(String? eid) {
    return ProfileRedaction.redactEid(eid, revealFull: showFullEid);
  }

  @override
  Widget build(BuildContext context) {
    if (eid == null && status == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isTinyScreen = MediaQuery.of(context).size.width < 400;
    final isSmallWidth = MediaQuery.of(context).size.width < 300;
    return Material(
      key: _eidKey,
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onContextMenu(_eidKey),
        onSecondaryTapDown: (details) => onContextMenu(_eidKey),
        onLongPress: () => onContextMenu(_eidKey),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          height: (isSmallWidth || eid == null) ? 40 : 54,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: eid == null
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        Icon(
                          eid != null
                              ? Icons.sim_card_outlined
                              : Icons.info_outline_rounded,
                          size: 14,
                          color: eid != null
                              ? AppTheme.onSurfaceVerySubtle(context)
                              : theme.colorScheme.error.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 8),
                        if (!isTinyScreen && eid != null) ...[
                          Text(
                            "EID: ",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.onSurfaceSubtle(context),
                            ),
                          ),
                        ],
                        Flexible(
                          child: Text(
                            eid != null ? _maskEid(eid) : (status ?? ""),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: eid != null
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                              color: eid != null
                                  ? AppTheme.onSurface(context)
                                  : theme.colorScheme.error,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (eid != null && extCardResource != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.storage_outlined,
                      size: 12,
                      color: AppTheme.onSurfaceVerySubtle(context),
                    ),
                    const SizedBox(width: 4),
                    if (!isTinyScreen)
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: "Free: ",
                                style: TextStyle(
                                  color: AppTheme.onSurfaceSubtle(context),
                                ),
                              ),
                              TextSpan(
                                text: SizeFormatter.format(
                                  extCardResource!.freeNonVolatileMemory ?? 0,
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                              const TextSpan(text: "  "),
                              TextSpan(
                                text: "RAM: ",
                                style: TextStyle(
                                  color: AppTheme.onSurfaceSubtle(context),
                                ),
                              ),
                              TextSpan(
                                text: SizeFormatter.format(
                                  extCardResource!.freeVolatileMemory ?? 0,
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      )
                    else
                      // On tiny screens, just show the free space value
                      Flexible(
                        child: Text(
                          SizeFormatter.format(
                            extCardResource!.freeNonVolatileMemory ?? 0,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.8,
                            ),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ), // Ink
      ), // InkWell
    ); // Material
  }
}
