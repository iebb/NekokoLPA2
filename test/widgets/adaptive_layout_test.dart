import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/services/division_regions.dart';
import 'package:nlpa2/theme/adaptive_layout.dart';

/// The unfolded iPhone Duo's inner display, with its division region.
const Size _duoInner = Size(951, 669);
const Rect _duoFold = Rect.fromLTWH(455.5, 0, 40, 669);

DisplayFeature _feature(
  Rect bounds, {
  DisplayFeatureType type = DisplayFeatureType.fold,
  DisplayFeatureState state = DisplayFeatureState.unknown,
}) => DisplayFeature(bounds: bounds, type: type, state: state);

Widget _atSize(
  WidgetTester tester,
  Size size,
  List<DisplayFeature> features,
  Widget child,
) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return MediaQuery(
    data: MediaQueryData(size: size, displayFeatures: features),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox.fromSize(size: size, child: child),
      ),
    ),
  );
}

void main() {
  test('width classes follow the Material breakpoints', () {
    expect(WindowWidthClass.of(466), WindowWidthClass.compact);
    expect(WindowWidthClass.of(599.9), WindowWidthClass.compact);
    expect(WindowWidthClass.of(600), WindowWidthClass.medium);
    expect(WindowWidthClass.of(839.9), WindowWidthClass.medium);
    expect(WindowWidthClass.of(_duoInner.width), WindowWidthClass.expanded);
  });

  test('only folds that divide the screen split the layout', () {
    expect(verticalFoldOf([_feature(_duoFold)]), _duoFold);
    // A cutout, a flat seamless fold and a horizontal hinge do not split
    // columns.
    expect(
      verticalFoldOf([
        _feature(
          const Rect.fromLTWH(400, 0, 150, 30),
          type: DisplayFeatureType.cutout,
        ),
        _feature(
          const Rect.fromLTWH(475, 0, 0, 669),
          state: DisplayFeatureState.postureFlat,
        ),
        _feature(const Rect.fromLTWH(0, 300, 951, 40)),
      ]),
      isNull,
    );
    expect(
      verticalFoldOf([
        _feature(
          const Rect.fromLTWH(475, 0, 0, 669),
          state: DisplayFeatureState.postureHalfOpened,
        ),
      ]),
      const Rect.fromLTWH(475, 0, 0, 669),
    );
  });

  test('a fold near an edge leaves a single pane', () {
    expect(FoldSplit.resolve(_duoFold.translate(-320, 0), 600), isNull);
    expect(
      FoldSplit.resolve(_duoFold, _duoInner.width),
      const FoldSplit(start: 455.5, end: 495.5, width: 951),
    );
  });

  test('fold columns stay clear of the fold', () {
    final fold = FoldSplit.resolve(_duoFold, _duoInner.width)!;
    final columns = foldColumns(
      start: 24,
      end: _duoInner.width - 24,
      fold: fold,
      minColumnWidth: 280,
      spacing: 16,
    );

    expect(columns, hasLength(2));
    expect(columns.first.left, 24);
    expect(columns.first.left + columns.first.width, fold.start);
    expect(columns.last.left, fold.end);
    expect(columns.last.left + columns.last.width, _duoInner.width - 24);

    // A wider pane holds more than one column.
    final wide = foldColumns(
      start: 0,
      end: 1600,
      fold: const FoldSplit(start: 790, end: 810, width: 1600),
      minColumnWidth: 280,
      spacing: 16,
    );
    expect(wide, hasLength(4));
    for (final column in wide) {
      final right = column.left + column.width;
      expect(right <= 790 || column.left >= 810, isTrue, reason: '$column');
    }
  });

  test('division regions outside the view are dropped', () {
    final regions = DivisionRegions.parse([
      {'left': 455.5, 'top': 0, 'width': 40, 'height': 669},
      {'left': 'bad'},
    ]);
    expect(regions, [
      _feature(_duoFold, state: DisplayFeatureState.postureHalfOpened),
    ]);

    expect(divisionRegionsInView(_duoInner, regions).single.bounds, _duoFold);

    // While folding, the outer display's size can arrive first.
    expect(divisionRegionsInView(const Size(466, 678), regions), isEmpty);

    // While rotating, the other orientation's size can arrive first.
    expect(
      divisionRegionsInView(Size(_duoInner.height, _duoInner.width), regions),
      isEmpty,
    );
    final laptop = DivisionRegions.parse([
      {'left': 0, 'top': 455.5, 'width': 669, 'height': 40},
    ]);
    expect(divisionRegionsInView(_duoInner, laptop), isEmpty);
    expect(
      divisionRegionsInView(const Size(669, 951), laptop).single.bounds,
      const Rect.fromLTWH(0, 455.5, 669, 40),
    );
  });

  test('a fully open fold is parsed as inactive', () {
    final regions = DivisionRegions.parse([
      {'left': 455.5, 'top': 0, 'width': 40, 'height': 669, 'active': false},
    ]);
    expect(regions.single.state, DisplayFeatureState.postureFlat);
  });

  group('division region scope', () {
    setUp(() => DivisionRegions.regions.value = const []);
    tearDown(() => DivisionRegions.regions.value = const []);

    Future<void> pumpScope(WidgetTester tester, Widget child) {
      tester.view
        ..physicalSize = _duoInner
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      return tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: _duoInner),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: DivisionRegionScope(child: child),
          ),
        ),
      );
    }

    testWidgets('an inactive fold splits layouts but not dialogs', (
      tester,
    ) async {
      late List<DisplayFeature> features;
      FoldSplit? split;
      await pumpScope(
        tester,
        FoldAwareBuilder(
          builder: (context, constraints, fold) {
            features = MediaQuery.displayFeaturesOf(context);
            split = fold;
            return const SizedBox.expand();
          },
        ),
      );
      expect(split, isNull);

      DivisionRegions.regions.value = [
        _feature(_duoFold, state: DisplayFeatureState.postureFlat),
      ];
      await tester.pump();
      const expected = FoldSplit(start: 455.5, end: 495.5, width: 951);
      expect(features, isEmpty);
      expect(split, expected);

      // Folding partway keeps the same split and moves dialogs off the fold.
      DivisionRegions.regions.value = [
        _feature(_duoFold, state: DisplayFeatureState.postureHalfOpened),
      ];
      await tester.pump();
      expect(features.single.bounds, _duoFold);
      expect(split, expected);
    });

    testWidgets('the app keeps its state as the fold comes and goes', (
      tester,
    ) async {
      await pumpScope(tester, const _Counter());
      final state = tester.state(find.byType(_Counter));

      for (final regions in [
        [_feature(_duoFold, state: DisplayFeatureState.postureHalfOpened)],
        [_feature(_duoFold, state: DisplayFeatureState.postureFlat)],
        const <DisplayFeature>[],
      ]) {
        DivisionRegions.regions.value = regions;
        await tester.pump();
        expect(tester.state(find.byType(_Counter)), same(state));
      }
    });
  });

  testWidgets('a full-width child gets the fold on its first frame', (
    tester,
  ) async {
    final splits = <FoldSplit?>[];
    await tester.pumpWidget(
      _atSize(
        tester,
        _duoInner,
        [_feature(_duoFold)],
        FoldAwareBuilder(
          builder: (context, constraints, fold) {
            splits.add(fold);
            return const SizedBox.expand();
          },
        ),
      ),
    );

    expect(splits, [const FoldSplit(start: 455.5, end: 495.5, width: 951)]);
  });

  testWidgets('an inset child gets the fold in its own coordinates', (
    tester,
  ) async {
    FoldSplit? split;
    await tester.pumpWidget(
      _atSize(
        tester,
        _duoInner,
        [_feature(_duoFold)],
        Row(
          children: [
            // A navigation rail and its divider.
            const SizedBox(width: 81),
            Expanded(
              child: FoldAwareBuilder(
                builder: (context, constraints, fold) {
                  split = fold;
                  return const SizedBox.expand();
                },
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(split, const FoldSplit(start: 374.5, end: 414.5, width: 870));
  });

  testWidgets('span columns place every item on one side of the fold', (
    tester,
  ) async {
    final fold = FoldSplit.resolve(_duoFold, _duoInner.width)!;
    final columns = foldColumns(
      start: 24,
      end: _duoInner.width - 24,
      fold: fold,
      minColumnWidth: 280,
      spacing: 16,
    );
    await tester.pumpWidget(
      _atSize(
        tester,
        _duoInner,
        const [],
        CustomScrollView(
          slivers: [
            SliverSpanColumns(
              columns: columns,
              itemCount: 5,
              mainAxisSpacing: 8,
              itemBuilder: (context, index) =>
                  SizedBox(key: ValueKey(index), height: 60.0 + index * 10),
            ),
          ],
        ),
      ),
    );

    for (var index = 0; index < 5; index++) {
      final rect = tester.getRect(find.byKey(ValueKey(index)));
      final column = columns[index % 2];
      expect(rect.left, moreOrLessEquals(column.left), reason: 'item $index');
      expect(rect.width, moreOrLessEquals(column.width), reason: 'item $index');
      expect(
        rect.right <= fold.start || rect.left >= fold.end,
        isTrue,
        reason: 'item $index at $rect',
      );
    }
  });
}

/// A stateful stand-in for the app below the scope.
class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
