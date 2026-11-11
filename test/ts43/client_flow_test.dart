import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/services/ts43_entitlement_http.dart';
import 'package:nlpa2/ts43/enums.dart';
import 'package:nlpa2/ts43/sim/aka.dart';
import 'package:nlpa2/ts43/sim/identity.dart';
import 'package:nlpa2/ts43/ts43_client.dart';
import 'package:nlpa2/ts43/types.dart';

/// Transport that replays canned ODSA responses in order.
class _FakeTransport implements Ts43Transport {
  final List<String> bodies;
  int _i = 0;
  final List<Ts43HttpRequest> sent = [];
  _FakeTransport(this.bodies);

  @override
  Future<Ts43HttpResponse> doRaw(Ts43HttpRequest request) async {
    sent.add(request);
    final body = bodies[_i.clamp(0, bodies.length - 1)];
    _i++;
    return Ts43HttpResponse(utf8.encode(body), const []);
  }

  @override
  void close() {}
}

class _FakeSource implements SourceChannel {
  @override
  Future<Identity> identity() async => const Identity(
    iccid: '8900000000000000001',
    imsi: '234107813240779',
    mcc: '234',
    mnc: '10',
    gid1: '5A',
  );

  @override
  Future<AkaResponse> authenticateAka(AkaRequest request) async =>
      throw StateError('AKA relay not expected in this test');
}

void main() {
  test('source-credential transfer reaches DownloadReady then Done', () async {
    final ac = base64.encode(utf8.encode('1\$smdp.test\$MID-1'));
    final transport = _FakeTransport([
      // Authenticate -> token
      jsonEncode({
        'TOKEN': {'token': 'TOK', 'Validity': '3600'},
      }),
      // CheckEligibility -> eligible
      jsonEncode({
        'APPLICATION': {'OperationResult': '1', 'PrimaryAppEligibility': '1'},
      }),
      // ManageSubscription -> download profile
      jsonEncode({
        'APPLICATION': {
          'OperationResult': '1',
          'SubscriptionResult': '2',
          'DownloadInfo': {
            'ProfileActivationCode': 'encodedValue=$ac',
            'ProfileIccid': '8900000000000000002',
          },
        },
      }),
    ]);

    final events = <Ts43Event>[];
    final client = Ts43Client(
      Ts43Config(
        transport: transport,
        entitlement: Entitlement(
          server: 'https://entitlement.test/ts43',
          channel: EntitlementChannel.google,
          transferType:
              TransferType.reusableActivationCode, // source-credential (3)
        ),
        source: Endpoint(
          channel: _FakeSource(),
          device: Device(imei: '350000000000006'),
        ),
        target: Endpoint(
          device: Device(
            imei: '350000000000006',
            eid: '89000000000000000000000000000001',
          ),
        ),
        appVersion: '1',
        onEvent: events.add,
      ),
    );

    final result = await client.transfer();
    expect(result.state, Ts43State.pendingDownload);
    expect(result.downloadConfig.activationCode, 'LPA:1\$smdp.test\$MID-1');
    expect(result.event, isA<DownloadReadyEvent>());

    // Source-credential path completes immediately on activation.
    final done = await client.completeActivation(
      result,
      const ActivationResult(iccid: '8900000000000000002'),
    );
    expect(done.state, Ts43State.done);
    expect(events.whereType<DoneEvent>().length, 1);

    // First request carried the EAP_ID (no token); later requests carried the token.
    expect(transport.sent.length, 3);
  });
}
