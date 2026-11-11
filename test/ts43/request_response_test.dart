import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/ts43/enums.dart';
import 'package:nlpa2/ts43/request.dart';
import 'package:nlpa2/ts43/response.dart';
import 'package:nlpa2/ts43/sim/identity.dart';
import 'package:nlpa2/ts43/types.dart';

void main() {
  final identity = Identity(
    iccid: '8900000000000000001',
    imsi: '234107813240779',
    mcc: '234',
    mnc: '10',
    gid1: '5A',
  );

  test('GET request builds EAP_ID and common fields', () {
    final prepared = buildPreparedRequest(
      entitlement: Entitlement(channel: EntitlementChannel.google),
      identity: identity,
      req: ServiceEntitlementRequest(
        app: 'ap2009',
        entitlementVersion: '9.0',
        terminalId: '350000000000006',
        terminalVendor: 'Goog',
        terminalModel: 'Pixel',
      ),
      op: OdsaOperation(operation: Operation.check),
      clientTs43: 'client-Primary-ODSA',
      realm: 'nai.epc',
    );
    expect(prepared.usePost, isFalse);
    expect(
      prepared.params['EAP_ID']!.first,
      '0234107813240779@nai.epc.mnc010.mcc234.3gppnetwork.org',
    );
    expect(prepared.params['operation']!.first, 'CheckEligibility');
    expect(prepared.params['app']!.first, 'ap2009');
    // EAP relay accept is added for the initial (token-less) request.
    expect(prepared.accept, contains('eap-relay'));
    final qs = prepared.queryString();
    expect(qs, contains('EAP_ID='));
    expect(qs, contains('operation=CheckEligibility'));
  });

  test('POST request emits JSON body', () {
    final prepared = buildPreparedRequest(
      entitlement: Entitlement(
        channel: EntitlementChannel.google,
        usePost: true,
      ),
      identity: identity,
      req: ServiceEntitlementRequest(app: 'ap2009', authenticationToken: 'TOK'),
      op: OdsaOperation(operation: Operation.manage),
      clientTs43: 'client-Primary-ODSA',
      realm: 'nai.epc',
    );
    expect(prepared.usePost, isTrue);
    final body = jsonDecode(prepared.jsonBody()) as Map<String, dynamic>;
    expect(body['token'], 'TOK');
    expect(body['IMSI'], '234107813240779');
    expect(body['operation'], 'ManageSubscription');
  });

  test('decodes JSON ODSA response with download info', () {
    final json = jsonEncode({
      'APPLICATION': {
        'OperationResult': 1,
        'SubscriptionResult': 2,
        'DownloadInfo': {
          'ProfileActivationCode':
              'encodedValue=' +
              base64.encode(utf8.encode('1\$smdp.example.com\$MATCH-123')),
          'ProfileIccid': '8900000000000000002',
        },
      },
    });
    final resp = OdsaResponse.decode(utf8.encode(json));
    expect(resp.operationResult, OperationResult.success);
    expect(resp.subscriptionResult, SubscriptionResult.downloadProfile);
    expect(resp.download.activationCode, 'LPA:1\$smdp.example.com\$MATCH-123');
    expect(resp.download.profileIccid, '8900000000000000002');
  });

  test('decodes XML ODSA response (token + eligibility)', () {
    const xml = '''
<?xml version="1.0"?>
<wap-provisioningdoc version="1.1">
  <characteristic type="TOKEN">
    <parm name="token" value="ABC123"/>
    <parm name="Validity" value="3600"/>
  </characteristic>
  <characteristic type="APPLICATION">
    <parm name="OperationResult" value="1"/>
    <parm name="PrimaryAppEligibility" value="1"/>
  </characteristic>
</wap-provisioningdoc>''';
    final resp = OdsaResponse.decode(utf8.encode(xml));
    expect(resp.authenticationToken, 'ABC123');
    expect(resp.authTokenValidity, 3600);
    expect(resp.operationResult, OperationResult.success);
    expect(resp.primaryAppEligibility, AppEligibility.enabled);
  });
}
