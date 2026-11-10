import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nlpa2/adapter/ble/bee_sim_adapter.dart';
import 'package:nlpa2/adapter/euicc_adapter.dart';
import 'package:nlpa2/l10n/app_localizations.dart';
import 'package:nlpa2/plugins/bee_sim_plugin.dart';
import 'package:nlpa2/plugins/plugin_base.dart';

// BeeSimPlugin.buildReaderActions is commented out, so there is no action to
// tap. Set this to false when it is restored.
const bool _firmwareActionOff = true;

void main() {
  testWidgets('offers no firmware action while the check is off', (
    tester,
  ) async {
    late List<Widget> actions;
    final adapter = _FakeBeeSimAdapter();
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          actions =
              BeeSimPlugin(
                httpClient: MockClient((_) => fail('no request')),
              ).buildReaderActions(
                context,
                ReaderActionContext(
                  adapter: adapter,
                  reader: Reader(
                    id: 'BeeSIM|test',
                    name: 'BeeSIM',
                    source: adapter,
                  ),
                  profiles: null,
                ),
              );
          return const SizedBox.shrink();
        },
      ),
    );
    expect(actions, isEmpty);
  }, skip: !_firmwareActionOff);

  testWidgets(
    'requires explicit confirmation before any firmware write',
    (tester) async {
      final adapter = _FakeBeeSimAdapter();
      await _pumpAction(tester, adapter);

      await tester.tap(find.byTooltip('Update BeeSIM firmware'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Keep the card powered'), findsOneWidget);
      expect(find.text('Update firmware'), findsOneWidget);
      expect(adapter.writtenRows, isEmpty);
      expect(adapter.resetCount, 0);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(adapter.writtenRows, isEmpty);
      expect(adapter.resetCount, 0);
    },
    skip: _firmwareActionOff,
  );

  testWidgets(
    'system back cannot hide the confirmation or active flow',
    (tester) async {
      final adapter = _FakeBeeSimAdapter();
      await _pumpAction(tester, adapter);

      await tester.tap(find.byTooltip('Update BeeSIM firmware'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Update firmware'), findsOneWidget);
      expect(adapter.writtenRows, isEmpty);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    },
    skip: _firmwareActionOff,
  );

  testWidgets(
    'no-update preflight never requests confirmation or writes',
    (tester) async {
      final adapter = _FakeBeeSimAdapter();
      await _pumpAction(tester, adapter, rows: const <String>[]);

      await tester.tap(find.byTooltip('Update BeeSIM firmware'));
      await tester.pumpAndSettle();

      expect(find.textContaining('already up to date'), findsOneWidget);
      expect(find.text('Update firmware'), findsNothing);
      expect(adapter.writtenRows, isEmpty);
      expect(adapter.resetCount, 0);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    },
    skip: _firmwareActionOff,
  );

  testWidgets('writes rows in order only after confirmation', (tester) async {
    final adapter = _FakeBeeSimAdapter();
    await _pumpAction(tester, adapter);

    await tester.tap(find.byTooltip('Update BeeSIM firmware'));
    await tester.pumpAndSettle();
    expect(adapter.writtenRows, isEmpty);

    await tester.tap(find.text('Update firmware'));
    await tester.pumpAndSettle();

    expect(adapter.writtenRows, <int>[2, 3, 4]);
    expect(adapter.resetCount, 1);
    expect(find.textContaining('Firmware update complete.'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  }, skip: _firmwareActionOff);

  testWidgets('stops after a rejected row and does not reset', (tester) async {
    final adapter = _FakeBeeSimAdapter(rejectRow: 3);
    await _pumpAction(tester, adapter);

    await tester.tap(find.byTooltip('Update BeeSIM firmware'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update firmware'));
    await tester.pumpAndSettle();

    expect(adapter.writtenRows, <int>[2, 3]);
    expect(adapter.resetCount, 0);
    expect(find.textContaining('Firmware update failed:'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  }, skip: _firmwareActionOff);

  testWidgets(
    'unexpected reset failure is not reported as success',
    (tester) async {
      final adapter = _FakeBeeSimAdapter(
        resetError: StateError('reset rejected'),
      );
      await _pumpAction(tester, adapter);

      await tester.tap(find.byTooltip('Update BeeSIM firmware'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Update firmware'));
      await tester.pumpAndSettle();

      expect(adapter.writtenRows, <int>[2, 3, 4]);
      expect(adapter.resetCount, 1);
      expect(find.textContaining('Firmware update failed:'), findsOneWidget);
      expect(find.textContaining('Firmware update complete.'), findsNothing);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    },
    skip: _firmwareActionOff,
  );
}

Future<void> _pumpAction(
  WidgetTester tester,
  _FakeBeeSimAdapter adapter, {
  List<String> rows = const <String>['AA', 'BB', 'CC'],
}) async {
  final client = MockClient(
    (_) async => http.Response(
      jsonEncode(<String, Object>{
        'status': 200,
        'msg': 'Update available',
        'data': rows,
        'total': 4,
        'index': 2,
      }),
      200,
    ),
  );
  final plugin = BeeSimPlugin(httpClient: client);
  final reader = Reader(
    id: 'BeeSIM|test-device',
    name: 'BeeSIM test',
    source: adapter,
  );

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          final actions = plugin.buildReaderActions(
            context,
            ReaderActionContext(
              adapter: adapter,
              reader: reader,
              profiles: null,
            ),
          );
          return Scaffold(body: Center(child: actions.single));
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeBeeSimAdapter extends BeeSimAdapter {
  _FakeBeeSimAdapter({this.rejectRow, this.resetError});

  final int? rejectRow;
  final Object? resetError;
  final List<int> writtenRows = <int>[];
  int resetCount = 0;

  @override
  Future<BeeSimUpgradeStatus> checkUpgrading() async {
    return const BeeSimUpgradeStatus(crc: 'ABCD', totalRows: 1, currentRow: 1);
  }

  @override
  Future<bool> writeFirmwareRow({
    required int totalRows,
    required int currentRow,
    required Uint8List rowBytes,
  }) async {
    writtenRows.add(currentRow);
    return currentRow != rejectRow;
  }

  @override
  Future<void> resetDevice() async {
    resetCount++;
    if (resetError != null) throw resetError!;
  }
}
