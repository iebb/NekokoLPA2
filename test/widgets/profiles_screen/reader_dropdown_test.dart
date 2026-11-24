import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/adapter/euicc_adapter.dart';
import 'package:nlpa2/adapter/remote/remocard_adapter.dart';
import 'package:nlpa2/widgets/profiles_screen/reader_dropdown.dart';

void main() {
  Widget buildDropdown(Reader reader) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => buildReaderDropdown(
            context: context,
            selectedReader: reader,
            readers: [reader],
            showFullEid: true,
          ),
        ),
      ),
    );
  }

  testWidgets('shows a 32-character RemoCard name when EID is absent', (
    tester,
  ) async {
    const deviceName = '123456789012345678901234567890123456';
    final reader = Reader(
      id: 'remocard:http://192.0.2.1:33777|$deviceName',
      name: 'http://192.0.2.1:33777/$deviceName',
      source: RemoCardAdapter('http://192.0.2.1:33777'),
      context: deviceName,
    );

    await tester.pumpWidget(buildDropdown(reader));

    expect(find.text('1234567890123456789012345678901…'), findsOneWidget);
    expect(find.text('Unknown EID'), findsNothing);
  });

  testWidgets('keeps the EID ahead of the RemoCard name', (tester) async {
    const eid = '89049032000000000000000000000001';
    final reader = Reader(
      id: 'remocard:http://192.0.2.1:33777|Living Room',
      name: 'http://192.0.2.1:33777/Living Room',
      source: RemoCardAdapter('http://192.0.2.1:33777'),
      context: 'Living Room',
      eid: eid,
    );

    await tester.pumpWidget(buildDropdown(reader));

    expect(find.text(eid), findsOneWidget);
    expect(find.text('Living Room'), findsNothing);
  });
}
