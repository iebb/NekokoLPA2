import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';

import '../services/division_regions.dart';

/// Material window width classes, used instead of per-screen breakpoints.
enum WindowWidthClass {
  compact,
  medium,
  expanded;

  static const double mediumMinWidth = 600;
  static const double expandedMinWidth = 840;

  static WindowWidthClass of(double width) {
    if (width >= expandedMinWidth) return expanded;
    if (width >= mediumMinWidth) return medium;
    return compact;
  }

  static WindowWidthClass ofContext(BuildContext context) =>
      of(MediaQuery.sizeOf(context).width);
}

/// The vertical fold or hinge that content should be split around, in the
/// coordinates of [features], or null.
///
/// Like [DisplayFeatureSubScreen], a feature divides the screen when it has
/// an area or when the device is half opened; a flat zero-width fold does not.
Rect? verticalFoldOf(Iterable<DisplayFeature> features) {
  for (final feature in features) {
    if (feature.type == DisplayFeatureType.cutout) continue;
    final bounds = feature.bounds;
    final divides =
        bounds.shortestSide > 0 ||
        feature.state == DisplayFeatureState.postureHalfOpened;
    if (divides && bounds.height > bounds.width) return bounds;
  }
  return null;
}

/// A vertical fold in a widget's own horizontal coordinates.
@immutable
class FoldSplit {
  const FoldSplit({required this.start, required this.end, required this.width})
    : assert(0 < start && start <= end && end < width);

  /// Panes narrower than this are not worth laying out on their own.
  static const double minPaneWidth = 160;

  /// The left edge of the fold.
  final double start;

  /// The right edge of the fold.
  final double end;

  /// The width of the area being split.
  final double width;

  /// The width of the pane left of the fold.
  double get leading => start;

  /// The width of the pane right of the fold.
  double get trailing => width - end;

  /// The width of the fold.
  double get gap => end - start;

  /// Resolves [fold], in local coordinates, against an area [width] wide.
  static FoldSplit? resolve(Rect fold, double width) {
    if (!width.isFinite) return null;
    final start = fold.left.clamp(0.0, width);
    final end = fold.right.clamp(0.0, width);
    if (start < minPaneWidth || width - end < minPaneWidth) return null;
    return FoldSplit(start: start, end: end, width: width);
  }

  @override
  bool operator ==(Object other) =>
      other is FoldSplit &&
      other.start == start &&
      other.end == end &&
      other.width == width;

  @override
  int get hashCode => Object.hash(start, end, width);

  @override
  String toString() => 'FoldSplit($start..$end of $width)';
}

/// A column's horizontal span in local coordinates.
typedef ColumnSpan = ({double left, double width});

/// Columns between [start] and [end] that keep clear of [fold].
///
/// Each side of the fold gets as many columns of at least [minColumnWidth] as
/// fit, and at least one. The fold is widened to [spacing] if it is narrower.
List<ColumnSpan> foldColumns({
  required double start,
  required double end,
  required FoldSplit fold,
  required double minColumnWidth,
  required double spacing,
}) {
  final widen = fold.gap < spacing ? (spacing - fold.gap) / 2 : 0.0;
  return [
    ..._paneColumns(start, fold.start - widen, minColumnWidth, spacing),
    ..._paneColumns(fold.end + widen, end, minColumnWidth, spacing),
  ];
}

List<ColumnSpan> _paneColumns(
  double start,
  double end,
  double minColumnWidth,
  double spacing,
) {
  final width = end - start;
  if (width <= 0) return const [];
  final count = ((width + spacing) / (minColumnWidth + spacing)).floor().clamp(
    1,
    1 << 10,
  );
  final columnWidth = (width - spacing * (count - 1)) / count;
  return [
    for (var i = 0; i < count; i++)
      (left: start + i * (columnWidth + spacing), width: columnWidth),
  ];
}

/// Independent columns at [columns], filled in reading order, as for a
/// waterfall layout whose columns differ in width around a fold.
class SliverSpanColumns extends StatelessWidget {
  const SliverSpanColumns({
    super.key,
    required this.columns,
    required this.itemCount,
    required this.itemBuilder,
    this.mainAxisSpacing = 0,
  });

  final List<ColumnSpan> columns;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double mainAxisSpacing;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.crossAxisExtent;
        final last = columns.isEmpty ? null : columns.last;
        // Columns resolved for another width, as in the frame after a resize,
        // fall back to one column rather than overflow.
        if (last == null || last.left + last.width > available + 0.5) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: EdgeInsets.only(bottom: mainAxisSpacing),
                child: itemBuilder(context, index),
              ),
              childCount: itemCount,
            ),
          );
        }
        return SliverCrossAxisGroup(slivers: _slivers(context, available));
      },
    );
  }

  List<Widget> _slivers(BuildContext context, double available) {
    final count = columns.length;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final slivers = <Widget>[];
    var x = 0.0;
    for (var i = 0; i < count; i++) {
      final column = columns[i];
      // Columns are physical, left to right; items follow reading order.
      final slot = isRtl ? count - 1 - i : i;
      // The group asserts that every child has some extent.
      if (column.left - x >= 0.5) {
        slivers.add(
          SliverConstrainedCrossAxis(
            maxExtent: column.left - x,
            sliver: const SliverToBoxAdapter(),
          ),
        );
      }
      final list = SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: EdgeInsets.only(bottom: mainAxisSpacing),
            child: itemBuilder(context, index * count + slot),
          ),
          childCount: (itemCount - slot + count - 1) ~/ count,
        ),
      );
      x = column.left + column.width;
      // The last column takes up any rounding left at the edge.
      slivers.add(
        i == count - 1 && available - x < 0.5
            ? SliverCrossAxisExpanded(flex: 1, sliver: list)
            : SliverConstrainedCrossAxis(maxExtent: column.width, sliver: list),
      );
    }
    if (available - x >= 0.5) {
      slivers.add(
        const SliverCrossAxisExpanded(flex: 1, sliver: SliverToBoxAdapter()),
      );
    }
    return slivers;
  }
}

/// Builds with the vertical fold, if any, in this widget's own coordinates.
///
/// An inactive fold, such as that of a fully open iPhone Duo, is reserved
/// too, so the layout does not rearrange as the device folds partway.
///
/// Display features are in view coordinates. A child as wide as the view
/// shares its horizontal origin; a narrower one is measured after layout and
/// again when its route finishes animating in, so it is built without the
/// fold for its first frame.
class FoldAwareBuilder extends StatefulWidget {
  const FoldAwareBuilder({super.key, required this.builder});

  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
    FoldSplit? fold,
  )
  builder;

  @override
  State<FoldAwareBuilder> createState() => _FoldAwareBuilderState();
}

class _FoldAwareBuilderState extends State<FoldAwareBuilder> {
  double? _originX;
  Animation<double>? _routeAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animation = ModalRoute.of(context)?.animation;
    if (animation != _routeAnimation) {
      _routeAnimation?.removeStatusListener(_onRouteStatus);
      _routeAnimation = animation?..addStatusListener(_onRouteStatus);
    }
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    super.dispose();
  }

  void _onRouteStatus(AnimationStatus status) {
    if (status.isCompleted) _measure(Duration.zero);
  }

  void _measure(Duration _) {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final originX = box.localToGlobal(Offset.zero).dx;
    if (originX != _originX) setState(() => _originX = originX);
  }

  @override
  Widget build(BuildContext context) {
    final fold =
        verticalFoldOf(MediaQuery.displayFeaturesOf(context)) ??
        verticalFoldOf(DivisionRegionScope.inactiveOf(context));
    final viewWidth = MediaQuery.sizeOf(context).width;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (fold == null) return widget.builder(context, constraints, null);
        final width = constraints.maxWidth;
        double? originX;
        if ((width - viewWidth).abs() < 0.5) {
          originX = 0;
        } else {
          WidgetsBinding.instance.addPostFrameCallback(_measure);
          originX = _originX;
        }
        final split = originX == null
            ? null
            : FoldSplit.resolve(fold.translate(-originX, 0), width);
        return widget.builder(context, constraints, split);
      },
    );
  }
}
