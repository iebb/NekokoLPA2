import 'package:flutter/material.dart';
import '../../models/asn1/rsp_definitions.g.dart';
import '../../adapter/euicc_adapter.dart';
import '../../l10n/app_localizations.dart';
import 'reader_tabs.dart';
import 'reader_dropdown.dart';
import 'action_button.dart';
import 'eid_container.dart';
import 'switch_mode_button.dart';
import '../../services/notification_service.dart';
import '../../theme/adaptive_layout.dart';

class ProfilesHeader extends StatefulWidget {
  final bool isWide;
  final bool useTabs;
  final bool isExtremelySmall;
  final double padding;
  final double paddingV;
  final List<Reader> readers;
  final Reader? selectedReader;
  final TabController? tabController;
  final String? eid;
  final String? status;
  final EUICCInfo2? info2;
  final bool showFullEid;
  final GlobalKey downloadButtonKey1;
  final GlobalKey downloadButtonKey2;
  final Function(Reader) onReaderChanged;
  final Function(Reader) onReaderRemove;
  final VoidCallback onReaderOpen;
  final VoidCallback onDisconnect;
  final VoidCallback onToggleEidVisibility;
  final Function(GlobalKey) onEidContextMenu;
  final VoidCallback? onDownload;
  final Function(GlobalKey)? onBatchDownload;
  final VoidCallback? onNotifications;
  final List<Widget> extraActions;
  final VoidCallback onRefreshNotifications;
  final String? currentMode;
  final String? alternativeMode;
  final VoidCallback? onSwitchMode;
  final bool isLocked;

  const ProfilesHeader({
    super.key,
    required this.isWide,
    required this.useTabs,
    required this.isExtremelySmall,
    required this.padding,
    required this.paddingV,
    required this.readers,
    required this.selectedReader,
    required this.tabController,
    required this.eid,
    this.status,
    required this.info2,
    required this.showFullEid,
    required this.downloadButtonKey1,
    required this.downloadButtonKey2,
    required this.onReaderChanged,
    required this.onReaderRemove,
    required this.onReaderOpen,
    required this.onDisconnect,
    required this.onToggleEidVisibility,
    required this.onEidContextMenu,
    required this.onSwitchMode,
    required this.onDownload,
    required this.onBatchDownload,
    required this.onNotifications,
    this.extraActions = const <Widget>[],
    required this.onRefreshNotifications,
    this.currentMode,
    this.alternativeMode,
    this.isLocked = false,
  });

  @override
  State<ProfilesHeader> createState() => _ProfilesHeaderState();
}

class _ProfilesHeaderState extends State<ProfilesHeader> {
  // GlobalKey for EID module to prevent state loss/flashing when moving Rows
  final GlobalKey _eidGlobalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    if (widget.readers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.padding,
        vertical: widget.paddingV,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isWide)
            FoldAwareBuilder(
              builder: (context, constraints, fold) => fold == null
                  ? _buildFirstRow(context)
                  : _buildFoldRow(context, fold),
            )
          else
            _buildFirstRow(context),

          // On Narrow Layout: EID and Buttons move to a second row
          if (!widget.isWide &&
              (widget.eid != null ||
                  widget.status != null ||
                  widget.onSwitchMode != null ||
                  widget.extraActions.isNotEmpty)) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _buildEidContainer(context)),
                SizedBox(width: widget.isExtremelySmall ? 1.0 : 4.0),
                _buildActionButtons(context),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFirstRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Reader Selection Area (Tabs or Dropdown)
        Expanded(
          flex: widget.isWide ? 2 : 1,
          child: _buildReaderSelector(context),
        ),

        // Disconnect button: same row as selector (Wide or Narrow Dropdown)
        if (widget.selectedReader != null &&
            (widget.isWide || !widget.useTabs)) ...[
          const SizedBox(width: 8),
          _buildDisconnectButton(context),
        ],

        // On Wide Layout: EID and Actions follow on the first row
        if (widget.isWide && (widget.eid != null || widget.status != null)) ...[
          const SizedBox(width: 8),
          Expanded(flex: 3, child: _buildEidContainer(context)),
          const SizedBox(width: 8),
          _buildActionButtons(context),
        ],
        // Specific case: Wide layout, No EID row, but can switch
        if (widget.isWide &&
            widget.eid == null &&
            widget.status == null &&
            (widget.onSwitchMode != null ||
                widget.extraActions.isNotEmpty)) ...[
          const Spacer(),
          _buildActionButtons(context),
        ],
      ],
    );
  }

  /// The wide header split around a fold: the reader on one side, the EID
  /// and actions on the other.
  Widget _buildFoldRow(BuildContext context, FoldSplit fold) {
    final hasEid = widget.eid != null || widget.status != null;
    final hasActions =
        hasEid || widget.onSwitchMode != null || widget.extraActions.isNotEmpty;
    final readerPane = Row(
      children: [
        Expanded(child: _buildReaderSelector(context)),
        if (widget.selectedReader != null) ...[
          const SizedBox(width: 8),
          _buildDisconnectButton(context),
        ],
      ],
    );
    final infoPane = Row(
      children: [
        if (hasEid)
          Expanded(child: _buildEidContainer(context))
        else
          const Spacer(),
        if (hasActions) ...[
          const SizedBox(width: 8),
          _buildActionButtons(context),
        ],
      ],
    );
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Row(
      textDirection: TextDirection.ltr,
      children: [
        SizedBox(width: fold.leading, child: isRtl ? infoPane : readerPane),
        SizedBox(width: fold.gap),
        SizedBox(width: fold.trailing, child: isRtl ? readerPane : infoPane),
      ],
    );
  }

  Widget _buildReaderSelector(BuildContext context) {
    // Keep internal keys stable
    if (widget.useTabs && widget.tabController != null) {
      return RepaintBoundary(
        child: ReaderTabs(
          key: const ValueKey('header_tabs'),
          tabController: widget.tabController!,
          readers: widget.readers,
        ),
      );
    }

    return buildReaderDropdown(
      context: context,
      selectedReader: widget.selectedReader,
      readers: widget.readers,
      showFullEid: widget.showFullEid,
      onChanged: (v) async {
        if (v != null) widget.onReaderChanged(v);
      },
      onRemove: widget.onReaderRemove,
      onOpen: widget.onReaderOpen,
    );
  }

  Widget _buildDisconnectButton(BuildContext context) {
    return ActionButton(
      onPressed: widget.onDisconnect,
      icon: Icons.link_off,
      label: AppLocalizations.of(context)!.disconnect,
      isDestructive: true,
    );
  }

  Widget _buildEidContainer(BuildContext context) {
    return RepaintBoundary(
      child: EidContainer(
        key: _eidGlobalKey, // Essential for stability across layout swaps
        eid: widget.eid,
        status: widget.status,
        extCardResource: widget.info2?.extCardResource,
        showFullEid: widget.showFullEid,
        onToggleEidVisibility: widget.onToggleEidVisibility,
        onContextMenu: widget.onEidContextMenu,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final gap = widget.isExtremelySmall ? 1.0 : 4.0;
    return RepaintBoundary(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.onSwitchMode != null &&
              widget.currentMode != null &&
              widget.alternativeMode != null) ...[
            SwitchModeButton(
              topLabel: widget.currentMode!,
              bottomLabel: widget.alternativeMode!,
              onPressed: widget.isLocked ? null : widget.onSwitchMode,
            ),
            SizedBox(width: gap),
          ],
          if (widget.onNotifications != null)
            ValueListenableBuilder<int>(
              valueListenable: NotificationService().pendingCount,
              builder: (context, badgeCount, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: NotificationService().isProcessing,
                  builder: (context, isProcessing, _) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: NotificationService().isFetching,
                      builder: (context, isFetching, _) {
                        return ActionButton(
                          icon: Icons.notifications_outlined,
                          badgeCount: badgeCount,
                          onPressed: widget.onNotifications,
                          label: AppLocalizations.of(context)!.notifications,
                          isLoading: isProcessing || isFetching,
                        );
                      },
                    );
                  },
                );
              },
            ),
          SizedBox(width: gap),
          ..._interleave(widget.extraActions, SizedBox(width: gap)),
          if (widget.extraActions.isNotEmpty) SizedBox(width: gap),
          if (widget.onDownload != null)
            ActionButton(
              key: widget.isWide
                  ? widget.downloadButtonKey1
                  : widget.downloadButtonKey2,
              icon: Icons.add,
              onPressed: (widget.selectedReader != null && !widget.isLocked)
                  ? widget.onDownload
                  : null,
              onLongPress:
                  (widget.selectedReader != null &&
                      widget.onBatchDownload != null &&
                      !widget.isLocked)
                  ? () => widget.onBatchDownload!(
                      widget.isWide
                          ? widget.downloadButtonKey1
                          : widget.downloadButtonKey2,
                    )
                  : null,
              label: AppLocalizations.of(context)!.downloadProfile,
            ),
        ],
      ),
    );
  }

  List<Widget> _interleave(List<Widget> items, Widget separator) {
    if (items.isEmpty) {
      return const <Widget>[];
    }
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        out.add(separator);
      }
      out.add(items[i]);
    }
    return out;
  }
}
