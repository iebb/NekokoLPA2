import 'package:flutter/material.dart';
import '../../models/euicc_profile.dart';
import '../profile_card.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../settings/app_settings.dart';
import '../../plugins/plugin_manager.dart';
import '../../theme/adaptive_layout.dart';

class ProfileListSection extends StatefulWidget {
  final List<EuiccProfile> profiles;
  final String? eid;
  final String? togglingIccid;
  final String? deletingIccid;
  final bool isWide;
  final bool isLocked;
  final double padding;
  final double paddingV;
  final Function(String iccid) getCardKey;
  final Function(EuiccProfile profile, bool value) onToggle;
  final Function(EuiccProfile profile, GlobalKey cardKey) onMenu;
  final Function(EuiccProfile profile) onTagTap;
  final Future<void> Function()? onRefresh;

  const ProfileListSection({
    super.key,
    required this.profiles,
    this.eid,
    this.togglingIccid,
    this.deletingIccid,
    required this.isWide,
    required this.padding,
    required this.paddingV,
    required this.getCardKey,
    required this.onToggle,
    required this.onMenu,
    required this.onTagTap,
    this.isLocked = false,
    this.onRefresh,
  });

  @override
  State<ProfileListSection> createState() => _ProfileListSectionState();
}

class _ProfileListSectionState extends State<ProfileListSection> {
  static const double _maxColumnWidth = 400;
  static const double _minFoldColumnWidth = 280;
  static const double _columnSpacing = 16;
  static const double _rowSpacing = 8;

  final ValueNotifier<double> _overscrollNotifier = ValueNotifier<double>(0);

  @override
  void dispose() {
    _overscrollNotifier.dispose();
    super.dispose();
  }

  Widget _buildCard(EuiccProfile p, {bool isCompact = false}) {
    final cardKey = widget.getCardKey(p.iccid) as GlobalKey;
    return RepaintBoundary(
      child: ProfileCard(
        key: ValueKey(p.iccid),
        cardKey: cardKey,
        profile: p,
        eid: widget.eid,
        isToggling: widget.togglingIccid == p.iccid,
        isDeleting: widget.deletingIccid == p.iccid,
        isLocked: widget.isLocked,
        isCompact: isCompact,
        onToggle: (v) => widget.onToggle(p, v),
        onMenu: () => widget.onMenu(p, cardKey),
        onTagTap: () => widget.onTagTap(p),
      ),
    );
  }

  Widget _buildHeaders() {
    return SliverToBoxAdapter(
      child: ListenableBuilder(
        listenable: PluginManager(),
        builder: (context, _) {
          return Column(
            children: PluginManager().buildHeaders(context, widget.eid),
          );
        },
      ),
    );
  }

  /// Column spans for the wide grid; on a folding screen no column crosses
  /// the fold.
  List<ColumnSpan> _wideColumns(
    double width,
    EdgeInsets inset,
    FoldSplit? fold,
  ) {
    final start = widget.padding + inset.left;
    final end = width - widget.padding - inset.right;
    if (end <= start) return const [];
    if (fold != null) {
      final columns = foldColumns(
        start: start,
        end: end,
        fold: fold,
        minColumnWidth: _minFoldColumnWidth,
        spacing: _columnSpacing,
      );
      if (columns.isNotEmpty) return columns;
    }
    final count = ((end - start) / _maxColumnWidth).ceil().clamp(1, 1 << 10);
    final columnWidth = (end - start - _columnSpacing * (count - 1)) / count;
    return [
      for (var i = 0; i < count; i++)
        (left: start + i * (columnWidth + _columnSpacing), width: columnWidth),
    ];
  }

  /// Rows of cards aligned across [columns].
  Widget _buildAlignedRows(List<ColumnSpan> columns, bool isRtl) {
    final count = columns.length;
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, rowIndex) {
        final children = <Widget>[];
        var x = 0.0;
        for (var i = 0; i < count; i++) {
          final column = columns[i];
          // Physical columns run left to right; items follow reading order.
          final itemIndex = rowIndex * count + (isRtl ? count - 1 - i : i);
          children
            ..add(SizedBox(width: column.left - x))
            ..add(
              SizedBox(
                width: column.width,
                child: itemIndex < widget.profiles.length
                    ? _buildCard(widget.profiles[itemIndex])
                    : null,
              ),
            );
          x = column.left + column.width;
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: _rowSpacing),
          child: Row(
            textDirection: TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        );
      }, childCount: (widget.profiles.length / count).ceil()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final inset = MediaQuery.paddingOf(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    Widget listContent;

    if (widget.isWide) {
      listContent = FoldAwareBuilder(
        builder: (context, constraints, fold) {
          final width = constraints.maxWidth;
          final columns = _wideColumns(width, inset, fold);
          if (columns.isEmpty) return const SizedBox.shrink();

          final waterfall = AppSettings().useWaterfallLayout;
          // Only the uniform masonry grid is inset by padding; the other
          // layouts place their columns from the left edge.
          final masonry = waterfall && fold == null;
          final Widget grid;
          if (!waterfall) {
            grid = _buildAlignedRows(columns, isRtl);
          } else if (!masonry) {
            grid = SliverSpanColumns(
              columns: columns,
              itemCount: widget.profiles.length,
              mainAxisSpacing: _rowSpacing,
              itemBuilder: (context, index) =>
                  _buildCard(widget.profiles[index]),
            );
          } else {
            grid = SliverMasonryGrid.count(
              crossAxisCount: columns.length,
              mainAxisSpacing: _rowSpacing,
              crossAxisSpacing: _columnSpacing,
              itemBuilder: (context, index) =>
                  _buildCard(widget.profiles[index]),
              childCount: widget.profiles.length,
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              _buildHeaders(),
              SliverPadding(
                padding: EdgeInsets.only(
                  left: masonry ? columns.first.left : 0,
                  right: masonry
                      ? width - columns.last.left - columns.last.width
                      : 0,
                  top: widget.paddingV,
                  bottom: widget.paddingV + 80,
                ),
                sliver: grid,
              ),
            ],
          );
        },
      );
    } else {
      listContent = CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          _buildHeaders(),
          SliverPadding(
            padding: EdgeInsets.only(
              left: widget.padding + inset.left,
              right: widget.padding + inset.right,
              top: widget.paddingV,
              bottom: widget.paddingV + 80,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildCard(widget.profiles[index], isCompact: true),
                childCount: widget.profiles.length,
              ),
            ),
          ),
        ],
      );
    }

    Widget content = NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          final pixels = notification.metrics.pixels;
          if (pixels < 0) {
            _overscrollNotifier.value = pixels.abs();
          } else if (_overscrollNotifier.value != 0) {
            _overscrollNotifier.value = 0;
          }
        }
        return false;
      },
      child: listContent,
    );

    if (widget.onRefresh != null) {
      content = RefreshIndicator(
        onRefresh: widget.onRefresh!,
        color: theme.colorScheme.primary,
        displacement: 60, // Move spinner down to avoid overlap with text
        child: content,
      );
    }

    final installedText = l10n.profilesInstalled(widget.profiles.length);

    return Stack(
      children: [
        ValueListenableBuilder<double>(
          valueListenable: _overscrollNotifier,
          builder: (context, overscroll, _) {
            if (overscroll <= 5) return const SizedBox.shrink();
            return Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: overscroll.clamp(
                  0,
                  60,
                ), // Clamp height to match displacement gap
                alignment: Alignment.bottomCenter, // Align to bottom of the gap
                padding: const EdgeInsets.only(bottom: 15),
                child: Opacity(
                  opacity: (overscroll / 40).clamp(0, 1),
                  child: Text(
                    installedText,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        content,
      ],
    );
  }
}
