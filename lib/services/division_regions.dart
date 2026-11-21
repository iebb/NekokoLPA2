import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../utils/platform_adapter.dart';

/// Division regions reported by UIKit, such as the fold of an unfolded
/// iPhone Duo, as folds in view coordinates.
///
/// Flutter's iOS embedder does not report these as display features, so the
/// Runner forwards them over a method channel.
///
/// A region is active, in [DisplayFeatureState.postureHalfOpened], while the
/// device is partially open, and inactive, in
/// [DisplayFeatureState.postureFlat], while it is fully open.
class DivisionRegions {
  DivisionRegions._();

  static const MethodChannel _channel = MethodChannel(
    'nekokolpa/division_regions',
  );

  static final ValueNotifier<List<DisplayFeature>> regions =
      ValueNotifier<List<DisplayFeature>>(const <DisplayFeature>[]);

  static bool _started = false;

  static Future<void> start() async {
    if (_started || !PlatformX.isIOS) return;
    _started = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'update') {
        regions.value = parse(call.arguments);
      }
    });
    try {
      await _channel.invokeMethod<void>('start');
    } on MissingPluginException {
      // Runner without the bridge, such as an app extension host.
    } on PlatformException {
      // Reserved regions are best effort; the layout works without them.
    }
  }

  @visibleForTesting
  static List<DisplayFeature> parse(Object? arguments) {
    if (arguments is! List) return const <DisplayFeature>[];
    final features = <DisplayFeature>[];
    for (final item in arguments) {
      if (item is! Map) continue;
      final left = item['left'];
      final top = item['top'];
      final width = item['width'];
      final height = item['height'];
      if (left is! num || top is! num || width is! num || height is! num) {
        continue;
      }
      features.add(
        DisplayFeature(
          bounds: Rect.fromLTWH(
            left.toDouble(),
            top.toDouble(),
            width.toDouble(),
            height.toDouble(),
          ),
          type: DisplayFeatureType.fold,
          state: item['active'] == false
              ? DisplayFeatureState.postureFlat
              : DisplayFeatureState.postureHalfOpened,
        ),
      );
    }
    return List<DisplayFeature>.unmodifiable(features);
  }
}

/// Adds the active [DivisionRegions] to [MediaQueryData.displayFeatures], so
/// dialogs, sheets and fold-aware layouts keep clear of a partially open
/// fold.
///
/// Inactive regions are not display features, as dialogs would then keep to
/// one side of a fully open fold. Layouts that split around the fold read
/// them from [inactiveOf] instead, so they keep the same arrangement as the
/// device folds partway.
class DivisionRegionScope extends StatefulWidget {
  const DivisionRegionScope({super.key, required this.child});

  final Widget child;

  /// The inactive division regions in view coordinates, or none outside a
  /// scope.
  static List<DisplayFeature> inactiveOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_InactiveDivisions>()
          ?.features ??
      const <DisplayFeature>[];

  @override
  State<DivisionRegionScope> createState() => _DivisionRegionScopeState();
}

class _DivisionRegionScopeState extends State<DivisionRegionScope> {
  @override
  void initState() {
    super.initState();
    DivisionRegions.start();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<DisplayFeature>>(
      valueListenable: DivisionRegions.regions,
      child: widget.child,
      builder: (context, regions, child) {
        final data = MediaQuery.of(context);
        final inView = divisionRegionsInView(data.size, regions);
        final active = [
          for (final region in inView)
            if (region.state == DisplayFeatureState.postureHalfOpened) region,
        ];
        // The same widgets are built with or without regions, so the app
        // keeps its state as the device folds.
        return MediaQuery(
          data: active.isEmpty
              ? data
              : data.copyWith(
                  displayFeatures: [...data.displayFeatures, ...active],
                ),
          child: _InactiveDivisions(
            features: [
              for (final region in inView)
                if (region.state != DisplayFeatureState.postureHalfOpened)
                  region,
            ],
            child: child!,
          ),
        );
      },
    );
  }
}

class _InactiveDivisions extends InheritedWidget {
  const _InactiveDivisions({required this.features, required super.child});

  final List<DisplayFeature> features;

  @override
  bool updateShouldNotify(_InactiveDivisions oldWidget) =>
      !listEquals(features, oldWidget.features);
}

/// The [regions] that lie in a view of [size] and run across it, clipped to
/// it.
///
/// The size and the regions arrive separately while the device folds or
/// rotates, so a region that does not fit the current size, such as the
/// outer display's or the other orientation's, is dropped until both agree.
@visibleForTesting
List<DisplayFeature> divisionRegionsInView(
  Size size,
  List<DisplayFeature> regions,
) {
  const slop = 0.5;
  final view = Offset.zero & size;
  bool fits(Rect r) =>
      r.left >= -slop &&
      r.top >= -slop &&
      r.right <= size.width + slop &&
      r.bottom <= size.height + slop;
  bool runsAcross(Rect r) =>
      (r.top <= slop && r.bottom >= size.height - slop) ||
      (r.left <= slop && r.right >= size.width - slop);
  return <DisplayFeature>[
    for (final region in regions)
      if (fits(region.bounds) && runsAcross(region.bounds))
        DisplayFeature(
          bounds: region.bounds.intersect(view),
          type: region.type,
          state: region.state,
        ),
  ];
}
