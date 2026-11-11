import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/ts43/entitlement.dart';
import 'package:nlpa2/ts43/enums.dart';
import 'package:nlpa2/ts43/errors.dart';
import 'package:nlpa2/ts43/sim/identity.dart';
import 'package:nlpa2/ts43/types.dart';
import 'package:nlpa2/ts43/websheet.dart';

const _records = '''
[
  {"mccmnc":"20404","gid1":"5A","carrierName":"SaskTel","channel":"google",
   "entitlementServer":"https://sasktel.example","transferTypePsim":2,
   "transferTypeEsim":2,"supportPsimToEsimTransfer":true,
   "supportEsimToEsimTransfer":true,"useHttpPost":false},
  {"mccmnc":"20404","gid1":null,"carrierName":"Fallback","channel":"google",
   "entitlementServer":"https://fallback.example","transferTypePsim":6,
   "transferTypeEsim":6,"supportPsimToEsimTransfer":true,
   "supportEsimToEsimTransfer":true,"useHttpPost":true}
]
''';

Identity _id({String gid1 = ''}) => Identity(
  iccid: '8900',
  imsi: '204040000000000',
  mcc: '204',
  mnc: '04',
  gid1: gid1,
);

void main() {
  group('entitlement discovery', () {
    final records = parseEntitlementRecords(_records);

    test('GID1 match wins over fallback', () {
      final e = discoverEntitlementForChannel(
        records,
        _id(gid1: '5A'),
        SimType.esim,
        EntitlementChannel.google,
      );
      expect(e.server, 'https://sasktel.example');
      expect(e.transferType, 2);
    });

    test('falls back to the null-GID1 record', () {
      final e = discoverEntitlementForChannel(
        records,
        _id(gid1: 'ZZ'),
        SimType.esim,
        EntitlementChannel.google,
      );
      expect(e.server, 'https://fallback.example');
      expect(e.usePost, isTrue);
      expect(e.transferType, 6);
    });

    test('unknown MCCMNC throws not found', () {
      expect(
        () => discoverEntitlementForChannel(
          records,
          Identity(iccid: '', imsi: '999990000', mcc: '999', mnc: '99'),
          SimType.esim,
          EntitlementChannel.google,
        ),
        throwsA(isA<EntitlementException>()),
      );
    });
  });

  group('websheet callback parsing', () {
    test('JSON activation code callback', () {
      final r = parseWebsheetResult(
        '{"event":"profileReadyWithActivationCode",'
        '"activationCode":"LPA:1\$smdp\$M","iccid":"8900"}',
      );
      expect(r.event, WebsheetCallbackEvent.profileReadyWithActivationCode);
      expect(r.activationCode, 'LPA:1\$smdp\$M');
      expect(r.iccid, '8900');
    });

    test('JS ODSAServiceFlow callback', () {
      final r = parseWebsheetResult(
        "TS43_ODSA_CALLBACK ODSAServiceFlow.dismissFlow()",
      );
      expect(r.event, WebsheetCallbackEvent.dismissFlow);
    });

    test('URL callback', () {
      final r = parseWebsheetResult(
        'https://carrier.example/_callback?event=finishFlow&next_action=acquireConfiguration',
      );
      expect(r.event, WebsheetCallbackEvent.finishFlow);
      expect(r.nextAction, Operation.acquireConf);
    });
  });
}
