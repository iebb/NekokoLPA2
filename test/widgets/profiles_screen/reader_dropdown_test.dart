import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/adapter/ccid/ccid_adapter.dart';
import 'package:nlpa2/adapter/euicc_adapter.dart';
import 'package:nlpa2/settings/app_settings.dart';
import 'package:nlpa2/widgets/profiles_screen/reader_dropdown.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleEid = '8904903200000000000000001234567890';

  String? copiedText;

  setUp(() {
    copiedText = null;
    AppSettings().setFullHideSensitiveData(false);
    AppSettings().setRevealSensitiveProfileData(false);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copiedText = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    AppSettings().setFullHideSensitiveData(false);
  });

  Future<void> pumpDropdown(WidgetTester tester) async {
    final reader = Reader(
      id: 'test:1',
      name: 'Test Reader',
      source: CcidAdapter(),
      eid: sampleEid,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => buildReaderDropdown(
              context: context,
              selectedReader: reader,
              readers: [reader],
              showFullEid: false,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('long-press copies the raw EID even under full-hide',
      (tester) async {
    AppSettings().setFullHideSensitiveData(true);
    await pumpDropdown(tester);
    await tester.longPress(find.text('Test Reader'));
    await tester.pump();
    expect(copiedText, sampleEid);
  });

  testWidgets('long-press copies the raw EID when masked', (tester) async {
    await pumpDropdown(tester);
    await tester.longPress(find.text('Test Reader'));
    await tester.pump();
    expect(copiedText, sampleEid);
  });
}
