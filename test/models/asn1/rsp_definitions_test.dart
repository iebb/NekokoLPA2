import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/models/asn1/rsp_definitions.g.dart';
import 'package:asn1_codegen/runtime.dart';

import 'asn1_hex.dart';

/// Behavioural tests for the generated SGP.22 ASN.1 model
/// (`lib/models/asn1/rsp_definitions.g.dart`).
///
/// Everything asserted here is *observable* behaviour - decoded field values,
/// encoded bytes, tag numbers and enum mappings - so the suite can be used to
/// prove that a rewritten code generator emits behaviourally identical Dart.
///
/// Expected tag numbers and field orders are taken from the ASN.1 sources in
/// `tools/asn1/RSPDefinitions.asn1` rather than from the generated Dart, so the
/// tests are an independent check. Where the generated code deviates from the
/// spec, the ACTUAL behaviour is pinned and flagged with a BUG/QUIRK comment.
void main() {
  // ==========================================================================
  // Fixtures. Every byte is written out by hand; whitespace is ignored by
  // `fromHex`, and the leading bytes of each line are the tag and length.
  // ==========================================================================

  // ES10b.GetEUICCChallenge response - SGP.22 GetEuiccChallengeResponse ::=
  // [46] SEQUENCE { euiccChallenge Octet16 }, tag 'BF2E', one 16-byte
  // OCTET STRING child under context tag '80'.
  const challengeHex =
      'BF2E 12' //          GetEuiccChallengeResponse [46]
      '  80 10 000102030405060708090A0B0C0D0E0F'; // euiccChallenge (16 bytes)

  // ES10b.GetEUICCInfo (info2) - EUICCInfo2 ::= [34] SEQUENCE, tag 'BF22'.
  const euiccInfo2Hex =
      'BF22 81 8D' //                     EUICCInfo2 [34]
      '  81 03 020200' //                 [1] baseProfilePackageVersion 2.2.0
      '  82 03 020200' //                 [2] lowestSvn 2.2.0
      '  83 03 050001' //                 [3] euiccFirmwareVersion 5.0.1
      '  84 0D' //                        [4] extCardResource (ETSI TS 102 226)
      '    81 01 08' //                     installedApplication = 8
      '    82 04 000186A0' //               freeNonVolatileMemory = 100000
      '    83 02 1234' //                   freeVolatileMemory = 4660
      '  85 04 07F80280' //               [5] uiccCapability BIT STRING
      '  86 03 090000' //                 [6] ts102241Version 9.0.0
      '  87 03 020300' //                 [7] globalplatformVersion 2.3.0
      '  88 03 06B040' //                 [8] euiccRspCapability BIT STRING
      '  A9 2C' //                        [9] euiccCiPKIdListForVerification
      '    04 14 81370F5125D0B1D208D4C3B232E64E077DA55E7C'
      '    04 14 C0BC70BA36929D43B467FF57570530E57AB8FCD8'
      '  AA 16' //                       [10] euiccCiPKIdListForSigning
      '    04 14 81370F5125D0B1D208D4C3B232E64E077DA55E7C'
      '  04 03 020100' //                     ppVersion 2.1.0 (untagged)
      '  0C 0D 47534D412D5341532D55502D31'; // sasAcreditationNumber

  // Same eUICC, but reporting the v3.x tail fields as well.
  const euiccInfo2V3Hex =
      'BF22 81 C8'
      '  81 03 020200'
      '  82 03 020200'
      '  83 03 050001'
      '  84 0D 81 01 08 82 04 000186A0 83 02 1234'
      '  85 04 07F80280'
      '  86 03 090000'
      '  87 03 020300'
      '  88 03 06B040'
      '  A9 2C'
      '    04 14 81370F5125D0B1D208D4C3B232E64E077DA55E7C'
      '    04 14 C0BC70BA36929D43B467FF57570530E57AB8FCD8'
      '  AA 16 04 14 81370F5125D0B1D208D4C3B232E64E077DA55E7C'
      '  04 03 020100'
      '  0C 0D 47534D412D5341532D55502D31'
      '  8D 02 0640' //                  [13] treProperties: isIntegrated
      '  8E 08 5452452D31323334' //      [14] treProductReference "TRE-1234"
      '  AF 05 30 03 030000' //          [15] additionalProfilePackageVersions
      '  90 01 00' //                    [16] lpaMode: lpad
      '  B1 16 04 14 C0BC70BA36929D43B467FF57570530E57AB8FCD8' // [17] v3 CI ids
      '  92 04 DEADBEEF' //              [18] additionalEuiccInfo
      '  93 03 030000'; //               [19] highestSvn 3.0.0

  // EUICCInfo2 from a v2.2 eUICC that omits the OPTIONAL [6] and [7] versions.
  const euiccInfo2NoOptionalVersionsHex =
      'BF22 6D'
      '  81 03 020200'
      '  82 03 020200'
      '  83 03 050001'
      '  84 0D 81 01 08 82 04 000186A0 83 02 1234'
      '  85 04 07F80280'
      '  88 03 06B040' //                [8] straight after [5]
      '  A9 16 04 14 81370F5125D0B1D208D4C3B232E64E077DA55E7C'
      '  AA 16 04 14 81370F5125D0B1D208D4C3B232E64E077DA55E7C'
      '  04 03 020100'
      '  0C 0D 47534D412D5341532D55502D31';

  // ProfileInfo ::= [PRIVATE 3] SEQUENCE, tag 'E3'.
  const profileInfoHex =
      'E3 73' //                          ProfileInfo [PRIVATE 3]
      '  5A 0A 98071992123456789001' //   iccid (BCD, nibble-swapped)
      '  4F 10 A0000005591010FFFFFFFF8900001100' // isdpAid, tag '4F'
      '  9F70 01 01' //                   [112] profileState: enabled
      '  90 06 4E656B6F6B6F' //           [16] profileNickname "Nekoko"
      '  91 07 5465737453504E' //         [17] serviceProviderName "TestSPN"
      '  92 0C 546573742050726F66696C65' //[18] profileName "Test Profile"
      '  95 01 02' //                     [21] profileClass: operational
      '  B6 18' //                        [22] notificationConfigurationInfo
      '    30 16'
      '      80 02 0780' //                 profileManagementOperation: install
      '      81 10 736D64702E6578616D706C652E636F6D' // "smdp.example.com"
      '  B7 05 80 03 22F010' //           [23] profileOwner, mccMnc 22F010
      '  99 02 0640' //                   [25] profilePolicyRules: ppr1
      '  9F24 01 00' //                   [36] enabledOnEsimPort 0
      '  9F25 03 04C4B4'; //              [37] profileSize 312500

  // A second, sparser ProfileInfo; every ProfileInfo field is OPTIONAL.
  const profileInfoMinimalHex =
      'E3 18'
      '  5A 0A 98071992123456789019' //   iccid
      '  9F70 01 00' //                   profileState: disabled
      '  92 06 5365636F6E64'; //          profileName "Second"

  // ES10c.GetProfilesInfo response - ProfileInfoListResponse ::= [45] CHOICE,
  // tag 'BF2D'; the profileInfoListOk alternative is context tag 'A0'.
  const profileInfoListOkHex =
      'BF2D 81 92'
      '  A0 81 8F'
      '    E3 73'
      '      5A 0A 98071992123456789001'
      '      4F 10 A0000005591010FFFFFFFF8900001100'
      '      9F70 01 01'
      '      90 06 4E656B6F6B6F'
      '      91 07 5465737453504E'
      '      92 0C 546573742050726F66696C65'
      '      95 01 02'
      '      B6 18 30 16 80 02 0780'
      '        81 10 736D64702E6578616D706C652E636F6D'
      '      B7 05 80 03 22F010'
      '      99 02 0640'
      '      9F24 01 00'
      '      9F25 03 04C4B4'
      '    E3 18'
      '      5A 0A 98071992123456789019'
      '      9F70 01 00'
      '      92 06 5365636F6E64';

  // The profileInfoListError alternative, context tag '81', undefinedError.
  const profileInfoListErrorHex = 'BF2D 03 81 01 7F';

  // NotificationMetadata ::= [47] SEQUENCE, tag 'BF2F'.
  const notificationMetadataHex =
      'BF2F 25'
      '  80 01 05' //                     [0] seqNumber 5
      '  81 02 0780' //                   [1] profileManagementOperation: install
      '  0C 10 736D64702E6578616D706C652E636F6D' // notificationAddress
      '  5A 0A 98071992123456789001'; //      iccid

  // PendingNotification ::= CHOICE { profileInstallationResult [55] ... },
  // i.e. an install notification arrives with the outer tag 'BF37'.
  const pendingInstallNotificationHex =
      'BF37 81 81' //                     ProfileInstallationResult [55]
      '  BF27 57' //                      [39] profileInstallationResultData
      '    80 08 0102030405060708' //     [0] transactionId
      '    BF2F 25' //                    [47] notificationMetadata
      '      80 01 05'
      '      81 02 0780'
      '      0C 10 736D64702E6578616D706C652E636F6D'
      '      5A 0A 98071992123456789001'
      '    06 09 2B0601040182E43801' //       smdpOid
      '    A2 18' //                      [2] finalResult CHOICE
      '      A0 16' //                        successResult
      '        4F 10 A0000005591010FFFFFFFF8900001100' // aid
      '        04 02 9000' //                            ppiResponse
      '  5F37 24 3044' //               [APPLICATION 55] euiccSignPIR (36 bytes)
      '    02020202020202020202020202020202'
      '    02020202020202020202020202020202'
      '    0202';

  // PendingNotification's otherSignedNotification alternative is an untagged
  // SEQUENCE (tag '30'). Truncated after the signature - the two Certificate
  // fields are omitted, which the positional decoder tolerates.
  const otherSignedNotificationHex =
      '30 4F'
      '  BF2F 25'
      '    80 01 05'
      '    81 02 0520' //                 notificationLocalDisable (named bit 2)
      '    0C 10 736D64702E6578616D706C652E636F6D'
      '    5A 0A 98071992123456789001'
      '  5F37 24 3044'
      '    02020202020202020202020202020202'
      '    02020202020202020202020202020202'
      '    0202';

  // ES8+.StoreMetadata - StoreMetadataRequest ::= [37] SEQUENCE, tag 'BF25'.
  const storeMetadataHex =
      'BF25 51'
      '  5A 0A 98071992123456789001' //   iccid
      '  91 07 5465737453504E' //         [17] serviceProviderName
      '  92 0C 546573742050726F66696C65' //[18] profileName
      '  95 01 02' //                     [21] profileClass: operational
      '  B6 18 30 16 80 02 0780'
      '    81 10 736D64702E6578616D706C652E636F6D'
      '  B7 05 80 03 22F010' //           [23] profileOwner
      '  99 02 0640' //                   [25] profilePolicyRules: ppr1
      '  9F21 03 04C4B4'; //              [33] estimatedProfileSize 312500

  // The same request from an SM-DP+ that relies on the DEFAULT for
  // profileClass and therefore omits tag '95'.
  const storeMetadataNoProfileClassHex =
      'BF25 3D'
      '  5A 0A 98071992123456789001'
      '  91 07 5465737453504E'
      '  92 0C 546573742050726F66696C65'
      '  B6 18 30 16 80 02 0780'
      '    81 10 736D64702E6578616D706C652E636F6D';

  const ski1Hex = '81370F5125D0B1D208D4C3B232E64E077DA55E7C';
  const ski2Hex = 'C0BC70BA36929D43B467FF57570530E57AB8FCD8';
  const iccidHex = '98071992123456789001';
  const isdpAidHex = 'A0000005591010FFFFFFFF8900001100';

  // ==========================================================================

  group('GetEuiccChallengeResponse (BF2E)', () {
    test('decodes the 16-byte challenge from real ES10b bytes', () {
      final resp = GetEuiccChallengeResponse.decode(fromHex(challengeHex));

      expect(resp.euiccChallenge, isNotNull);
      expect(resp.euiccChallenge!.length, 16);
      expect(toHex(resp.euiccChallenge!), '000102030405060708090A0B0C0D0E0F');
    });

    test('re-encodes byte-for-byte from the decoded value', () {
      final resp = GetEuiccChallengeResponse.decode(fromHex(challengeHex));
      expect(toHex(resp.encode()), normHex(challengeHex));
    });

    test('QUIRK: encode(tag:) is ignored once the source node is retained', () {
      // Every generated class short-circuits `encode()` to `asn1.encodedBytes`
      // when it was produced by `decode`, so an explicit tag override has no
      // effect at all on a decoded value.
      final resp = GetEuiccChallengeResponse.decode(fromHex(challengeHex));
      expect(toHex(resp.encode(tag: 0xBF01)), normHex(challengeHex));
    });

    test('encodes a hand-built value with the spec default tag BF2E', () {
      final resp = GetEuiccChallengeResponse(
        euiccChallenge: fromHex('000102030405060708090A0B0C0D0E0F'),
      );
      expect(toHex(resp.encode()), normHex(challengeHex));
    });

    test('round-trips constructor -> encode -> decode', () {
      final original = GetEuiccChallengeResponse(
        euiccChallenge: fromHex('FFEEDDCCBBAA99887766554433221100'),
      );
      final decoded = GetEuiccChallengeResponse.decode(original.encode());

      expect(decoded.euiccChallenge, original.euiccChallenge);
    });

    test('honours an explicit tag override when built by hand', () {
      final resp = GetEuiccChallengeResponse(euiccChallenge: fromHex('AABB'));
      expect(
        toHex(resp.encode(tag: 0xBF2E)),
        'BF2E04'
        '8002AABB',
      );
    });

    test('accepts a pre-parsed Asn1Node as well as raw bytes', () {
      final node = Asn1Reader(fromHex(challengeHex)).readNext()!;
      final fromNode = GetEuiccChallengeResponse.decode(node);
      final fromBytes = GetEuiccChallengeResponse.decode(fromHex(challengeHex));

      expect(fromNode.euiccChallenge, fromBytes.euiccChallenge);
    });

    test('decoding unparseable input yields an empty value, not a throw', () {
      final resp = GetEuiccChallengeResponse.decode(Uint8List(0));

      expect(resp.euiccChallenge, isNull);
      expect(resp.asn1, isNull);
      // With no retained node, encode() falls back to the default tag.
      expect(toHex(resp.encode()), 'BF2E00');
    });

    test('GetEuiccChallengeRequest encodes as the empty SEQUENCE BF2E00', () {
      expect(toHex(GetEuiccChallengeRequest().encode()), 'BF2E00');
    });

    test('toString reports the challenge as hex', () {
      final resp = GetEuiccChallengeResponse.decode(fromHex(challengeHex));
      expect(
        resp.toString(),
        contains('euiccChallenge: 000102030405060708090A0B0C0D0E0F'),
      );
    });
  });

  group('EUICCInfo2 (BF22)', () {
    test('decodes the version fields', () {
      final info = EUICCInfo2.decode(fromHex(euiccInfo2Hex));

      expect(toHex(info.baseProfilePackageVersion!), '020200');
      expect(toHex(info.lowestSvn!), '020200');
      expect(toHex(info.euiccFirmwareVersion!), '050001');
      expect(toHex(info.ts102241Version!), '090000');
      expect(toHex(info.globalplatformVersion!), '020300');
      expect(toHex(info.ppVersion!), '020100');
    });

    test('decodes extCardResource as a nested structure', () {
      final info = EUICCInfo2.decode(fromHex(euiccInfo2Hex));

      expect(info.extCardResource, isNotNull);
      expect(info.extCardResource!.installedApplication, 8);
      expect(info.extCardResource!.freeNonVolatileMemory, 100000);
      expect(info.extCardResource!.freeVolatileMemory, 4660);
    });

    test('decodes the uiccCapability BIT STRING into named bits', () {
      final info = EUICCInfo2.decode(fromHex(euiccInfo2Hex));
      final caps = info.uiccCapability!;

      // '07 F8 02 80': 7 unused bits, so named bits 0..4, 14 and 16 are set.
      expect(caps.value & UICCCapability.contactlessSupport, isNonZero);
      expect(caps.value & UICCCapability.usimSupport, isNonZero);
      expect(caps.value & UICCCapability.isimSupport, isNonZero);
      expect(caps.value & UICCCapability.csimSupport, isNonZero);
      expect(caps.value & UICCCapability.akaMilenage, isNonZero);
      expect(caps.value & UICCCapability.javacard, isNonZero);
      expect(caps.value & UICCCapability.multipleUsimSupport, isNonZero);

      expect(caps.value & UICCCapability.akaCave, 0);
      expect(caps.value & UICCCapability.multos, 0);
      expect(caps.value, 81951);
    });

    test('decodes the euiccRspCapability BIT STRING into named bits', () {
      final info = EUICCInfo2.decode(fromHex(euiccInfo2Hex));
      final caps = info.euiccRspCapability!;

      // '06 B0 40': named bits 0, 2, 3 and 9.
      expect(caps.value & EuiccRspCapability.additionalProfile, isNonZero);
      expect(caps.value & EuiccRspCapability.rpmSupport, isNonZero);
      expect(caps.value & EuiccRspCapability.testProfileSupport, isNonZero);
      expect(
        caps.value & EuiccRspCapability.enterpriseProfilesSupport,
        isNonZero,
      );
      expect(caps.value & EuiccRspCapability.loadCrlSupport, 0);
      expect(caps.value, 525);
    });

    test('decodes the SEQUENCE OF SubjectKeyIdentifier fields', () {
      final info = EUICCInfo2.decode(fromHex(euiccInfo2Hex));

      expect(info.euiccCiPKIdListForVerification, hasLength(2));
      expect(toHex(info.euiccCiPKIdListForVerification![0]), ski1Hex);
      expect(toHex(info.euiccCiPKIdListForVerification![1]), ski2Hex);

      expect(info.euiccCiPKIdListForSigning, hasLength(1));
      expect(toHex(info.euiccCiPKIdListForSigning![0]), ski1Hex);
    });

    test('decodes sasAcreditationNumber as a string', () {
      final info = EUICCInfo2.decode(fromHex(euiccInfo2Hex));
      expect(info.sasAcreditationNumber, 'GSMA-SAS-UP-1');
    });

    test('leaves absent OPTIONAL fields null', () {
      final info = EUICCInfo2.decode(fromHex(euiccInfo2Hex));

      expect(info.euiccCategory, isNull);
      expect(info.forbiddenProfilePolicyRules, isNull);
      expect(info.certificationDataObject, isNull);
      expect(info.treProperties, isNull);
      expect(info.lpaMode, isNull);
      expect(info.highestSvn, isNull);
      expect(info.iotSpecificInfo, isNull);
    });

    test('re-encodes byte-for-byte from the decoded value', () {
      final info = EUICCInfo2.decode(fromHex(euiccInfo2Hex));
      expect(toHex(info.encode()), normHex(euiccInfo2Hex));
    });

    test('skips absent OPTIONAL versions without shifting later fields', () {
      // [6] and [7] are OPTIONAL and are tag-guarded in the decoder, so the
      // BIT STRING that follows still lands in euiccRspCapability.
      final info = EUICCInfo2.decode(fromHex(euiccInfo2NoOptionalVersionsHex));

      expect(info.ts102241Version, isNull);
      expect(info.globalplatformVersion, isNull);
      expect(info.euiccRspCapability!.value, 525);
      expect(info.uiccCapability!.value, 81951);
      expect(info.sasAcreditationNumber, 'GSMA-SAS-UP-1');
      expect(toHex(info.encode()), normHex(euiccInfo2NoOptionalVersionsHex));
    });

    test('decodes the v3.x tail fields', () {
      final info = EUICCInfo2.decode(fromHex(euiccInfo2V3Hex));

      expect(info.treProductReference, 'TRE-1234');
      expect(info.additionalProfilePackageVersions, hasLength(1));
      expect(toHex(info.additionalProfilePackageVersions![0]), '030000');
      expect(info.lpaMode, LpaMode.lpad);
      expect(info.euiccCiPKIdListForSigningV3, hasLength(1));
      expect(toHex(info.euiccCiPKIdListForSigningV3![0]), ski2Hex);
      expect(toHex(info.additionalEuiccInfo!), 'DEADBEEF');
      expect(toHex(info.highestSvn!), '030000');
      expect(toHex(info.encode()), normHex(euiccInfo2V3Hex));
    });

    test('decodes the treProperties BIT STRING as bits', () {
      // RSPDefinitions.asn1 declares treProperties [13] as a BIT STRING with
      // named bits isDiscrete(0)/isIntegrated(1)/usesRemoteMemory(2), so
      // '8D 02 0640' is isIntegrated alone.
      final info = EUICCInfo2.decode(fromHex(euiccInfo2V3Hex));

      expect(info.treProperties, EUICCInfo2_treProperties.isIntegrated);
      // Re-encoding reproduces the source bytes because the node is kept.
      expect(toHex(info.encode()), normHex(euiccInfo2V3Hex));
    });

    test('round-trips a hand-built value through encode -> decode', () {
      final original = EUICCInfo2(
        baseProfilePackageVersion: fromHex('020200'),
        lowestSvn: fromHex('020200'),
        euiccFirmwareVersion: fromHex('050001'),
        extCardResource: ExtendedCardResource(
          installedApplication: 8,
          freeNonVolatileMemory: 100000,
          freeVolatileMemory: 4660,
        ),
        uiccCapability: UICCCapability(81951),
        ts102241Version: fromHex('090000'),
        globalplatformVersion: fromHex('020300'),
        euiccRspCapability: EuiccRspCapability(525),
        euiccCiPKIdListForVerification: [fromHex(ski1Hex), fromHex(ski2Hex)],
        euiccCiPKIdListForSigning: [fromHex(ski1Hex)],
        ppVersion: fromHex('020100'),
        sasAcreditationNumber: 'GSMA-SAS-UP-1',
      );

      final decoded = EUICCInfo2.decode(original.encode());

      expect(
        decoded.baseProfilePackageVersion,
        original.baseProfilePackageVersion,
      );
      expect(decoded.lowestSvn, original.lowestSvn);
      expect(decoded.euiccFirmwareVersion, original.euiccFirmwareVersion);
      expect(decoded.ts102241Version, original.ts102241Version);
      expect(decoded.globalplatformVersion, original.globalplatformVersion);
      expect(decoded.ppVersion, original.ppVersion);
      expect(decoded.sasAcreditationNumber, 'GSMA-SAS-UP-1');
      expect(decoded.uiccCapability!.value, 81951);
      expect(decoded.euiccRspCapability!.value, 525);
      expect(decoded.extCardResource!.installedApplication, 8);
      expect(decoded.extCardResource!.freeNonVolatileMemory, 100000);
      expect(decoded.extCardResource!.freeVolatileMemory, 4660);
      expect(decoded.euiccCiPKIdListForVerification, hasLength(2));
      expect(toHex(decoded.euiccCiPKIdListForVerification![1]), ski2Hex);
    });

    test('BUG: a hand-built extCardResource is emitted as A4, not 84', () {
      // The spec declares `extCardResource [4] OCTET STRING`, i.e. primitive
      // context tag '84' (real eUICCs send '84'). The generator models it as a
      // constructed sub-structure and emits 'A4'. Decoding is unaffected
      // because the decoder ignores the child tag here, but a value built from
      // the public constructor does NOT re-encode to the wire format.
      final info = EUICCInfo2(
        baseProfilePackageVersion: fromHex('020200'),
        extCardResource: ExtendedCardResource(installedApplication: 8),
      );
      final children = Asn1Reader(info.encode()).readNext()!.children;

      expect(children[0].tag, 0x81);
      expect(children[1].tag, 0xA4);
      expect(children[1].tag, isNot(0x84));
    });

    test('locates mandatory members by tag, not by position', () {
      // A truncated EUICCInfo2 carrying only [1] and [8]. Members are found by
      // tag, so the absent ones stay null instead of shifting the [8] BIT
      // STRING into lowestSvn.
      final info = EUICCInfo2.decode(
        fromHex('BF22 0A  81 03 020200  88 03 06B040'),
      );

      expect(toHex(info.baseProfilePackageVersion!), '020200');
      expect(info.lowestSvn, isNull);
      expect(info.euiccFirmwareVersion, isNull);
      expect(info.euiccRspCapability, isNotNull);
      expect(
        info.euiccRspCapability!.value & EuiccRspCapability.additionalProfile,
        isNonZero,
      );
    });

    test(
      'an element the build does not know about does not derail the rest',
      () {
        // EXTENSIBILITY IMPLIED: a newer card may add members. EUICCInfo2 goes
        // up to [20] plus [25], so [30] is one this build cannot know about;
        // it must not cost us the [3] that follows it.
        final info = EUICCInfo2.decode(
          fromHex(
            'BF22 14' //                      four members of five bytes each
            '  81 03 020200'
            '  82 03 020201'
            '  9E 03 AABBCC' //               [30], unknown to this build
            '  83 03 050001',
          ),
        );

        expect(toHex(info.baseProfilePackageVersion!), '020200');
        expect(toHex(info.lowestSvn!), '020201');
        expect(toHex(info.euiccFirmwareVersion!), '050001');
      },
    );

    test('members arriving out of order are still placed correctly', () {
      final info = EUICCInfo2.decode(
        fromHex('BF22 0A  88 03 06B040  81 03 020200'),
      );

      expect(toHex(info.baseProfilePackageVersion!), '020200');
      expect(info.euiccRspCapability, isNull); // consumed before [1] was sought
    });
  });

  group('ProfileInfo (E3)', () {
    test('decodes every populated field of a realistic ES10c entry', () {
      final profile = ProfileInfo.decode(fromHex(profileInfoHex));

      expect(toHex(profile.iccid!), iccidHex);
      expect(toHex(profile.isdpAid!), isdpAidHex);
      expect(profile.profileState, ProfileState.enabled);
      expect(profile.profileNickname, 'Nekoko');
      expect(profile.serviceProviderName, 'TestSPN');
      expect(profile.profileName, 'Test Profile');
      expect(profile.profileClass, ProfileClass.operational);
      expect(profile.enabledOnEsimPort, 0);
      expect(profile.profileSize, 312500);
    });

    test('decodes the nested notificationConfigurationInfo SEQUENCE OF', () {
      final profile = ProfileInfo.decode(fromHex(profileInfoHex));
      final config = profile.notificationConfigurationInfo!;

      expect(config, hasLength(1));
      expect(
        config[0].profileManagementOperation!.value,
        NotificationEvent.notificationInstall,
      );
      expect(config[0].notificationAddress, 'smdp.example.com');
    });

    test('decodes profileOwner and profilePolicyRules', () {
      final profile = ProfileInfo.decode(fromHex(profileInfoHex));

      expect(toHex(profile.profileOwner!.mccMnc!), '22F010');
      expect(profile.profileOwner!.gid1, isNull);
      expect(profile.profilePolicyRules!.value, PprIds.ppr1);
    });

    test('leaves untransmitted OPTIONAL fields null', () {
      final profile = ProfileInfo.decode(fromHex(profileInfoHex));

      expect(profile.iconType, isNull);
      expect(profile.icon, isNull);
      expect(profile.dpProprietaryData, isNull);
      expect(profile.rpmConfiguration, isNull);
      expect(profile.hriServerAddress, isNull);
      expect(profile.serviceDescription, isNull);
    });

    test('re-encodes byte-for-byte from the decoded value', () {
      final profile = ProfileInfo.decode(fromHex(profileInfoHex));
      expect(toHex(profile.encode()), normHex(profileInfoHex));
    });

    test('decodes a sparse entry, skipping absent fields by tag', () {
      final profile = ProfileInfo.decode(fromHex(profileInfoMinimalHex));

      expect(toHex(profile.iccid!), '98071992123456789019');
      expect(profile.isdpAid, isNull);
      expect(profile.profileState, ProfileState.disabled);
      expect(profile.profileNickname, isNull);
      expect(profile.profileName, 'Second');
      expect(toHex(profile.encode()), normHex(profileInfoMinimalHex));
    });

    test('a hand-built ProfileInfo encodes to exactly the wire fixture', () {
      final profile = ProfileInfo(
        iccid: fromHex(iccidHex),
        isdpAid: fromHex(isdpAidHex),
        profileState: ProfileState.enabled,
        profileNickname: 'Nekoko',
        serviceProviderName: 'TestSPN',
        profileName: 'Test Profile',
        profileClass: ProfileClass.operational,
        notificationConfigurationInfo: [
          NotificationConfigurationInformation(
            profileManagementOperation: NotificationEvent(
              NotificationEvent.notificationInstall,
            ),
            notificationAddress: 'smdp.example.com',
          ),
        ],
        profileOwner: OperatorId(mccMnc: fromHex('22F010')),
        profilePolicyRules: PprIds(PprIds.ppr1),
        enabledOnEsimPort: 0,
        profileSize: 312500,
      );

      expect(toHex(profile.encode()), normHex(profileInfoHex));
    });

    test('encodes the two-byte tags 9F70 / 9F24 / 9F25 byte-wise', () {
      // A folded tag is written as its identifier octets: 0x9F70 must come
      // out as '9F 70' (SGP.22 tag for profileState), not as base-128 octets.
      final profile = ProfileInfo(
        profileState: ProfileState.enabled,
        enabledOnEsimPort: 1,
        profileSize: 5,
      );
      expect(
        toHex(profile.encode()),
        'E30C'
        '9F700101'
        '9F240101'
        '9F250105',
      );
    });

    test('QUIRK: strings are Latin-1, not UTF-8, in both directions', () {
      // `String.fromCharCodes` / `String.codeUnits` treat each byte as one code
      // unit. RSPDefinitions.asn1 declares these fields as UTF8String and real
      // SM-DP+s send UTF-8, so '43 61 66 C3 A9' ("Cafe" + U+00E9 in UTF-8)
      // decodes as mojibake instead of "Cafeé".
      final decoded = ProfileInfo.decode(fromHex('E3 07 92 05 436166C3A9'));
      expect(decoded.profileName, 'CafÃ©');

      // ... and encoding writes one byte per code unit (Latin-1), not UTF-8.
      final encoded = ProfileInfo(profileName: 'Café').encode();
      expect(
        toHex(encoded),
        'E306'
        '9204436166E9',
      );
    });

    test('BUG: code points above U+00FF are truncated when encoding', () {
      // U+65E5; `Uint8List.fromList(codeUnits)` keeps only the low byte (0xE5).
      final encoded = ProfileInfo(profileName: '日').encode();
      expect(
        toHex(encoded),
        'E303'
        '9201E5',
      );
    });
  });

  group('ProfileInfoListResponse (BF2D)', () {
    test('decodes the profileInfoListOk alternative', () {
      final resp = ProfileInfoListResponse.decode(
        fromHex(profileInfoListOkHex),
      );

      expect(resp.profileInfoListError, isNull);
      expect(resp.profileInfoListOk, hasLength(2));
      expect(toHex(resp.profileInfoListOk![0].iccid!), iccidHex);
      expect(resp.profileInfoListOk![0].profileState, ProfileState.enabled);
      expect(resp.profileInfoListOk![1].profileName, 'Second');
      expect(resp.profileInfoListOk![1].profileState, ProfileState.disabled);
    });

    test('decodes the profileInfoListError alternative', () {
      final resp = ProfileInfoListResponse.decode(
        fromHex(profileInfoListErrorHex),
      );

      expect(resp.profileInfoListOk, isNull);
      expect(resp.profileInfoListError, ProfileInfoListError.undefinedError);
      expect(resp.profileInfoListError!.value, 127);
    });

    test('re-encodes both alternatives byte-for-byte', () {
      expect(
        toHex(
          ProfileInfoListResponse.decode(
            fromHex(profileInfoListOkHex),
          ).encode(),
        ),
        normHex(profileInfoListOkHex),
      );
      expect(
        toHex(
          ProfileInfoListResponse.decode(
            fromHex(profileInfoListErrorHex),
          ).encode(),
        ),
        normHex(profileInfoListErrorHex),
      );
    });

    test('a hand-built list encodes to exactly the wire fixture', () {
      final resp = ProfileInfoListResponse(
        profileInfoListOk: [
          ProfileInfo.decode(fromHex(profileInfoHex)),
          ProfileInfo.decode(fromHex(profileInfoMinimalHex)),
        ],
      );
      expect(toHex(resp.encode()), normHex(profileInfoListOkHex));
    });

    test('a hand-built error response encodes to BF2D 03 81 01 7F', () {
      final resp = ProfileInfoListResponse(
        profileInfoListError: ProfileInfoListError.undefinedError,
      );
      expect(toHex(resp.encode()), 'BF2D0381017F');
    });

    test('the CHOICE decoder is tag-driven, so order does not matter', () {
      // profileInfoListOk is 'A0', profileInfoListError is '81'; the generated
      // CHOICE decoder switches on the child tag rather than on position.
      final resp = ProfileInfoListResponse.decode(
        fromHex('BF2D 07  81 01 01  A0 02 E3 00'),
      );

      expect(
        resp.profileInfoListError,
        ProfileInfoListError.incorrectInputValues,
      );
      expect(resp.profileInfoListOk, hasLength(1));
    });
  });

  group('NotificationMetadata (BF2F)', () {
    test('decodes seqNumber, event bits, address and iccid', () {
      final meta = NotificationMetadata.decode(
        fromHex(notificationMetadataHex),
      );

      expect(meta.seqNumber, 5);
      expect(
        meta.profileManagementOperation!.value,
        NotificationEvent.notificationInstall,
      );
      expect(meta.notificationAddress, 'smdp.example.com');
      expect(toHex(meta.iccid!), iccidHex);
    });

    test('re-encodes byte-for-byte from the decoded value', () {
      final meta = NotificationMetadata.decode(
        fromHex(notificationMetadataHex),
      );
      expect(toHex(meta.encode()), normHex(notificationMetadataHex));
    });

    test('a hand-built value encodes to exactly the wire fixture', () {
      final meta = NotificationMetadata(
        seqNumber: 5,
        profileManagementOperation: NotificationEvent(
          NotificationEvent.notificationInstall,
        ),
        notificationAddress: 'smdp.example.com',
        iccid: fromHex(iccidHex),
      );
      expect(toHex(meta.encode()), normHex(notificationMetadataHex));
    });

    test('the OPTIONAL iccid is tag-guarded', () {
      final meta = NotificationMetadata.decode(
        fromHex(
          'BF2F 19  80 01 07  81 02 0410  0C 10'
          '736D64702E6578616D706C652E636F6D',
        ),
      );

      expect(meta.seqNumber, 7);
      expect(meta.iccid, isNull);
      expect(
        meta.profileManagementOperation!.value,
        NotificationEvent.notificationLocalDelete,
      );
    });

    test('encodes each notification event to the SGP.22 BIT STRING bytes', () {
      Uint8List eventBytes(int bit) {
        final encoded = NotificationMetadata(
          profileManagementOperation: NotificationEvent(bit),
        ).encode();
        return Asn1Reader(encoded).readNext()!.children.single.value;
      }

      // BIT STRING named bit N is the (7-N mod 8)'th bit of octet N/8, with a
      // leading "unused bits" octet - so bit 0 alone is '07 80'.
      expect(toHex(eventBytes(NotificationEvent.notificationInstall)), '0780');
      expect(
        toHex(eventBytes(NotificationEvent.notificationLocalEnable)),
        '0640',
      );
      expect(
        toHex(eventBytes(NotificationEvent.notificationLocalDisable)),
        '0520',
      );
      expect(
        toHex(eventBytes(NotificationEvent.notificationLocalDelete)),
        '0410',
      );
      expect(toHex(eventBytes(NotificationEvent.loadRpmPackageResult)), '0001');
    });
  });

  group('PendingNotification (CHOICE)', () {
    test('dispatches on the outer tag BF37 to profileInstallationResult', () {
      final pending = PendingNotification.decode(
        fromHex(pendingInstallNotificationHex),
      );

      expect(pending.profileInstallationResult, isNotNull);
      expect(pending.otherSignedNotification, isNull);
      expect(pending.loadRpmPackageResultSigned, isNull);
    });

    test('decodes the nested install notification metadata', () {
      final pending = PendingNotification.decode(
        fromHex(pendingInstallNotificationHex),
      );
      final data =
          pending.profileInstallationResult!.profileInstallationResultData!;

      expect(toHex(data.transactionId!), '0102030405060708');
      expect(toHex(data.smdpOid!), '2B0601040182E43801');
      expect(data.notificationMetadata!.seqNumber, 5);
      expect(
        data.notificationMetadata!.profileManagementOperation!.value,
        NotificationEvent.notificationInstall,
      );
      expect(
        data.notificationMetadata!.notificationAddress,
        'smdp.example.com',
      );
    });

    test('decodes the finalResult CHOICE as successResult', () {
      final pending = PendingNotification.decode(
        fromHex(pendingInstallNotificationHex),
      );
      final finalResult = pending
          .profileInstallationResult!
          .profileInstallationResultData!
          .finalResult!;

      expect(finalResult.errorResult, isNull);
      expect(toHex(finalResult.successResult!.aid!), isdpAidHex);
      expect(toHex(finalResult.successResult!.ppiResponse!), '9000');
    });

    test('decodes euiccSignPIR under the application tag 5F37', () {
      final pending = PendingNotification.decode(
        fromHex(pendingInstallNotificationHex),
      );
      expect(pending.profileInstallationResult!.euiccSignPIR, hasLength(36));
    });

    test('re-encodes byte-for-byte from the decoded value', () {
      final pending = PendingNotification.decode(
        fromHex(pendingInstallNotificationHex),
      );
      expect(toHex(pending.encode()), normHex(pendingInstallNotificationHex));
    });

    test('dispatches on tag 30 to otherSignedNotification', () {
      final pending = PendingNotification.decode(
        fromHex(otherSignedNotificationHex),
      );

      expect(pending.profileInstallationResult, isNull);
      expect(pending.otherSignedNotification, isNotNull);

      final meta = pending.otherSignedNotification!.tbsOtherNotification!;
      expect(meta.seqNumber, 5);
      expect(
        meta.profileManagementOperation!.value,
        NotificationEvent.notificationLocalDisable,
      );
      expect(
        pending.otherSignedNotification!.euiccNotificationSignature,
        hasLength(36),
      );
      expect(toHex(pending.encode()), normHex(otherSignedNotificationHex));
    });

    test('an unknown outer tag leaves every alternative null', () {
      final pending = PendingNotification.decode(fromHex('BF20 02 AABB'));

      expect(pending.profileInstallationResult, isNull);
      expect(pending.otherSignedNotification, isNull);
      expect(pending.loadRpmPackageResultSigned, isNull);
      // The node is still retained, so the bytes survive a round trip.
      expect(toHex(pending.encode()), 'BF2002AABB');
    });

    test(
      'QUIRK: a hand-built CHOICE encodes with no wrapper unless tagged',
      () {
        // For a CHOICE the generator returns the selected alternative verbatim
        // when no tag is supplied, instead of wrapping it in the default 0x30.
        final pending = PendingNotification(
          profileInstallationResult: ProfileInstallationResult(
            euiccSignPIR: fromHex('AABB'),
          ),
        );

        expect(
          toHex(pending.encode()),
          'BF3705'
          '5F3702AABB',
        );
        expect(
          toHex(pending.encode(tag: 0x30)),
          '3008'
          'BF37055F3702AABB',
        );
      },
    );

    test('an empty hand-built CHOICE encodes to no bytes at all', () {
      expect(PendingNotification().encode(), isEmpty);
    });
  });

  group('StoreMetadataRequest (BF25)', () {
    test('decodes the ES8+ metadata a profile is installed with', () {
      final req = StoreMetadataRequest.decode(fromHex(storeMetadataHex));

      expect(toHex(req.iccid!), iccidHex);
      expect(req.serviceProviderName, 'TestSPN');
      expect(req.profileName, 'Test Profile');
      expect(req.profileClass, ProfileClass.operational);
      expect(req.profilePolicyRules!.value, PprIds.ppr1);
      expect(req.estimatedProfileSize, 312500);
      expect(toHex(req.profileOwner!.mccMnc!), '22F010');
      expect(req.notificationConfigurationInfo, hasLength(1));
      expect(
        req.notificationConfigurationInfo![0].notificationAddress,
        'smdp.example.com',
      );
      expect(req.iconType, isNull);
      expect(req.icon, isNull);
    });

    test('re-encodes byte-for-byte from the decoded value', () {
      final req = StoreMetadataRequest.decode(fromHex(storeMetadataHex));
      expect(toHex(req.encode()), normHex(storeMetadataHex));
    });

    test('a hand-built request encodes to exactly the wire fixture', () {
      final req = StoreMetadataRequest(
        iccid: fromHex(iccidHex),
        serviceProviderName: 'TestSPN',
        profileName: 'Test Profile',
        profileClass: ProfileClass.operational,
        notificationConfigurationInfo: [
          NotificationConfigurationInformation(
            profileManagementOperation: NotificationEvent(
              NotificationEvent.notificationInstall,
            ),
            notificationAddress: 'smdp.example.com',
          ),
        ],
        profileOwner: OperatorId(mccMnc: fromHex('22F010')),
        profilePolicyRules: PprIds(PprIds.ppr1),
        estimatedProfileSize: 312500,
      );

      expect(toHex(req.encode()), normHex(storeMetadataHex));
    });

    test('omitting the DEFAULTed profileClass keeps the following field', () {
      // `profileClass [21] ProfileClass DEFAULT operational` may be absent, so
      // the decoder must check tag '95' before consuming an element. It used
      // not to: the following 'B6' was eaten as profileClass, which both left
      // profileClass null and silently lost notificationConfigurationInfo.
      final req = StoreMetadataRequest.decode(
        fromHex(storeMetadataNoProfileClassHex),
      );

      expect(req.iccid, isNotNull);
      expect(req.serviceProviderName, 'TestSPN');
      expect(req.profileName, 'Test Profile');
      // Absent on the wire. The generated code does not materialise ASN.1
      // DEFAULT values, so this stays null rather than becoming operational.
      expect(req.profileClass, isNull);
      expect(req.notificationConfigurationInfo, hasLength(1));
      expect(
        req.notificationConfigurationInfo![0].notificationAddress,
        'smdp.example.com',
      );
      // The bytes still survive a round trip via the retained node.
      expect(toHex(req.encode()), normHex(storeMetadataNoProfileClassHex));
    });
  });

  group('EnableProfileRequest / DisableProfileRequest', () {
    // SGP.22 ES10c. profileIdentifier is an untagged CHOICE, so X.680 30.6 c)
    // makes its automatic [0] tag explicit: the alternative is wrapped in 'A0'
    // rather than having its own tag overwritten. This layout was confirmed
    // against a real eUICC, which accepted these requests and performed the
    // switch. The ICCIDs are the stored, nibble-swapped form as they come out
    // of ProfileInfo, which is what goes back on the wire unaltered.
    const enabledIccid = '98000000000000000081';
    const disabledIccid = '98000000000000000062';

    test('encodes an enable-by-ICCID request', () {
      final request = EnableProfileRequest(
        profileIdentifier: EnableProfileRequest_profileIdentifier(
          iccid: fromHex(enabledIccid),
        ),
        refreshFlag: false,
      );
      expect(
        toHex(request.encode()),
        'BF31 11' //          EnableProfileRequest [49]
                'A0 0C' //    [0] profileIdentifier, explicit CHOICE wrapper
                '5A 0A $enabledIccid' // iccid [APPLICATION 26]
                '81 01 00' // [1] refreshFlag FALSE
            .replaceAll(' ', ''),
      );
    });

    test('encodes a disable-by-ICCID request', () {
      final request = DisableProfileRequest(
        profileIdentifier: DisableProfileRequest_profileIdentifier(
          iccid: fromHex(disabledIccid),
        ),
        refreshFlag: false,
      );
      expect(toHex(request.encode()), 'BF3211A00C5A0A${disabledIccid}810100');
    });

    test('refreshFlag true encodes as FF, not 01', () {
      final request = EnableProfileRequest(
        profileIdentifier: EnableProfileRequest_profileIdentifier(
          iccid: fromHex(enabledIccid),
        ),
        refreshFlag: true,
      );
      expect(toHex(request.encode()), endsWith('8101FF'));
    });

    test('the ISD-P AID alternative uses tag 4F inside the same wrapper', () {
      final request = EnableProfileRequest(
        profileIdentifier: EnableProfileRequest_profileIdentifier(
          isdpAid: fromHex(isdpAidHex),
        ),
        refreshFlag: false,
      );
      expect(toHex(request.encode()), 'BF3117A0124F10${isdpAidHex}810100');
    });

    test('decodes the responses the card returns', () {
      // Both are [49]/[50] SEQUENCE with a single automatic [0] result.
      final enabled = EnableProfileResponse.decode(fromHex('BF31 03 80 01 00'));
      expect(enabled.enableResult, EnableProfileResponse_enableResult.ok);

      final disabled = DisableProfileResponse.decode(
        fromHex('BF32 03 80 01 00'),
      );
      expect(disabled.disableResult, DisableProfileResponse_disableResult.ok);
    });

    test('decodes a refusal without inventing a result', () {
      final response = EnableProfileResponse.decode(
        fromHex('BF32 03 80 01 02'), // profileNotInDisabledState
      );
      expect(
        response.enableResult,
        EnableProfileResponse_enableResult.profileNotInDisabledState,
      );
    });

    test('a request round-trips through its own decoder', () {
      final request = EnableProfileRequest(
        profileIdentifier: EnableProfileRequest_profileIdentifier(
          iccid: fromHex(enabledIccid),
        ),
        refreshFlag: true,
      );
      final decoded = EnableProfileRequest.decode(request.encode());
      expect(toHex(decoded.profileIdentifier!.iccid!), enabledIccid);
      expect(decoded.refreshFlag, isTrue);
    });
  });

  group('SEQUENCE OF a typedef element', () {
    test('encodes additionalProfilePackageVersions as raw OCTET STRINGs', () {
      // VersionType is a typedef for Uint8List, not a class. The encoder used
      // to call .encode() on each element, which threw NoSuchMethodError as
      // soon as this optional field was populated.
      final info = EUICCInfo2(
        additionalProfilePackageVersions: [
          fromHex('020000'),
          fromHex('020200'),
        ],
      );
      // [15] SEQUENCE OF, so tag 'AF', each element a universal OCTET STRING.
      expect(
        toHex(info.encode()),
        'BF220C AF0A 0403020000 0403020200'.replaceAll(' ', ''),
      );
    });

    test('decodes the element bytes whatever tag the element carries', () {
      // The v3 fixture writes each element as '30 03' rather than '04 03'.
      // Decoding reads the element's content without checking its tag, so both
      // forms yield the same version bytes -- which is why the broken encoder
      // went unnoticed for so long.
      final info = EUICCInfo2.decode(fromHex(euiccInfo2V3Hex));
      expect(info.additionalProfilePackageVersions, hasLength(1));
      expect(toHex(info.additionalProfilePackageVersions!.first), '030000');
    });
  });

  group('ExtendedCardResource (ETSI TS 102 226)', () {
    // Carried as the content of EUICCInfo2.extCardResource, tag '84'.
    const installed = '81010A'; //       [1] installedApplication  = 10
    const freeNvm = '820400162740'; //   [2] freeNonVolatileMemory = 1451840
    const freeVol = '83027FE3'; //       [3] freeVolatileMemory    = 32739

    /// Wraps content in tag '84' with a computed length, so a fixture cannot
    /// silently disagree with itself.
    Uint8List ecr(String contentHex) {
      final content = fromHex(contentHex);
      return Uint8List.fromList([0x84, content.length, ...content]);
    }

    test('decodes the layout a real eUICC sends', () {
      final r = ExtendedCardResource.decode(ecr('$installed$freeNvm$freeVol'));
      expect(r.installedApplication, 10);
      expect(r.freeNonVolatileMemory, 1451840);
      expect(r.freeVolatileMemory, 32739);
    });

    // ETSI makes all three mandatory, but cards vary. What matters is that an
    // unexpected layout reads as absent: a wrong memory figure would be shown
    // to the user as if it were real, whereas null is rendered as unknown.
    // These components are OPTIONAL in Supplementary.asn1 precisely so the
    // decoder checks tags instead of counting positions.
    const layouts = <String, String>{
      'installedApplication omitted': '$freeNvm$freeVol',
      'freeNonVolatileMemory omitted': '$installed$freeVol',
      'freeVolatileMemory omitted': '$installed$freeNvm',
      'wrapped in the FF21 template': 'FF210D$installed$freeNvm$freeVol',
      'reversed order': '$freeVol$freeNvm$installed',
      'unknown element first': '8401AA$installed$freeNvm$freeVol',
      'unknown element in the middle': '${installed}8401AA$freeNvm$freeVol',
      'empty': '',
    };

    layouts.forEach((name, content) {
      test('never invents a value when $name', () {
        final r = ExtendedCardResource.decode(ecr(content));
        expect(r.installedApplication, anyOf(isNull, 10));
        expect(r.freeNonVolatileMemory, anyOf(isNull, 1451840));
        expect(r.freeVolatileMemory, anyOf(isNull, 32739));
      });
    });

    test('skips a leading element that is not tag 81', () {
      final r = ExtendedCardResource.decode(ecr('$freeNvm$freeVol'));
      expect(r.installedApplication, isNull);
      expect(r.freeNonVolatileMemory, 1451840);
      expect(r.freeVolatileMemory, 32739);
    });
  });

  group('generated enum mappings', () {
    /// Asserts `.value` and `fromValue` agree in both directions and that
    /// unmapped integers come back as null.
    void checkEnum<T>(
      List<T> values,
      int Function(T) valueOf,
      T? Function(int) fromValue,
      List<int> expectedValues,
      List<int> unknownValues,
    ) {
      expect(values.map(valueOf).toList(), expectedValues);
      for (final v in values) {
        expect(fromValue(valueOf(v)), v);
      }
      for (final unknown in unknownValues) {
        expect(fromValue(unknown), isNull, reason: 'value $unknown');
      }
    }

    test('ProfileState: disabled(0), enabled(1)', () {
      checkEnum<ProfileState>(
        ProfileState.values,
        (e) => e.value,
        ProfileStateExt.fromValue,
        [0, 1],
        [-1, 2, 127],
      );
    });

    test('ProfileClass: test(0), provisioning(1), operational(2)', () {
      checkEnum<ProfileClass>(
        ProfileClass.values,
        (e) => e.value,
        ProfileClassExt.fromValue,
        [0, 1, 2],
        [3, 127],
      );
    });

    test('IconType: jpg(0), png(1)', () {
      checkEnum<IconType>(
        IconType.values,
        (e) => e.value,
        IconTypeExt.fromValue,
        [0, 1],
        [2],
      );
    });

    test('LpaMode: lpad(0), lpae(1)', () {
      checkEnum<LpaMode>(
        LpaMode.values,
        (e) => e.value,
        LpaModeExt.fromValue,
        [0, 1],
        [2],
      );
    });

    test('EUICCInfo2_euiccCategory: other(0)..contactlessEuicc(3)', () {
      checkEnum<EUICCInfo2_euiccCategory>(
        EUICCInfo2_euiccCategory.values,
        (e) => e.value,
        EUICCInfo2_euiccCategoryExt.fromValue,
        [0, 1, 2, 3],
        [4, 127],
      );
    });

    test('ProfileInfoListError is sparse: 1, 11, 127', () {
      checkEnum<ProfileInfoListError>(
        ProfileInfoListError.values,
        (e) => e.value,
        ProfileInfoListErrorExt.fromValue,
        [1, 11, 127],
        [0, 2, 10, 12, 126, 128],
      );
    });

    test('EnableProfileResponse_enableResult skips the unused value 8', () {
      checkEnum<EnableProfileResponse_enableResult>(
        EnableProfileResponse_enableResult.values,
        (e) => e.value,
        EnableProfileResponse_enableResultExt.fromValue,
        [0, 1, 2, 3, 4, 5, 6, 7, 9, 10, 127],
        [8, 11, 126],
      );
    });

    test('an unknown enum value on the wire decodes to null, not a throw', () {
      // ProfileInfo profileState '9F70 01 09' is not a defined ProfileState.
      final profile = ProfileInfo.decode(fromHex('E3 04 9F70 01 09'));
      expect(profile.profileState, isNull);
      // ... and the original bytes still round-trip.
      expect(toHex(profile.encode()), 'E3049F700109');
    });
  });

  group('bit-string flag classes', () {
    // SGP.22 assigns each named bit an index N; the generator must map it to
    // `1 << N`. Values below come from tools/asn1/RSPDefinitions.asn1.
    test('NotificationEvent bit indices match the spec', () {
      expect(NotificationEvent.notificationInstall, 1 << 0);
      expect(NotificationEvent.notificationLocalEnable, 1 << 1);
      expect(NotificationEvent.notificationLocalDisable, 1 << 2);
      expect(NotificationEvent.notificationLocalDelete, 1 << 3);
      expect(NotificationEvent.notificationRpmEnable, 1 << 4);
      expect(NotificationEvent.notificationRpmDisable, 1 << 5);
      expect(NotificationEvent.notificationRpmDelete, 1 << 6);
      expect(NotificationEvent.loadRpmPackageResult, 1 << 7);
    });

    test('PprIds bit indices match the spec', () {
      expect(PprIds.pprUpdateControl, 1 << 0);
      expect(PprIds.ppr1, 1 << 1);
      expect(PprIds.ppr2, 1 << 2);
    });

    test('ServiceDescription bit indices match the spec', () {
      expect(ServiceDescription.voice, 1 << 0);
      expect(ServiceDescription.data, 1 << 1);
    });

    test('EuiccRspCapability bit indices match the spec', () {
      expect(EuiccRspCapability.additionalProfile, 1 << 0);
      expect(EuiccRspCapability.loadCrlSupport, 1 << 1);
      expect(EuiccRspCapability.rpmSupport, 1 << 2);
      expect(EuiccRspCapability.testProfileSupport, 1 << 3);
      expect(EuiccRspCapability.deviceInfoExtensibilitySupport, 1 << 4);
      expect(EuiccRspCapability.serviceSpecificDataSupport, 1 << 5);
      expect(EuiccRspCapability.hriServerAddressSupport, 1 << 6);
      expect(EuiccRspCapability.serviceProviderMessageSupport, 1 << 7);
      expect(EuiccRspCapability.lpaProxySupport, 1 << 8);
      expect(EuiccRspCapability.enterpriseProfilesSupport, 1 << 9);
      expect(EuiccRspCapability.serviceDescriptionSupport, 1 << 10);
      expect(EuiccRspCapability.deviceChangeSupport, 1 << 11);
      expect(EuiccRspCapability.encryptedDeviceChangeDataSupport, 1 << 12);
      expect(EuiccRspCapability.estimatedProfileSizeIndicationSupport, 1 << 13);
      expect(EuiccRspCapability.profileSizeInProfilesInfoSupport, 1 << 14);
      expect(EuiccRspCapability.crlStaplingV3Support, 1 << 15);
      expect(EuiccRspCapability.certChainV3VerificationSupport, 1 << 16);
      expect(EuiccRspCapability.signedSmdsResponseV3Support, 1 << 17);
      expect(EuiccRspCapability.euiccRspCapInInfo1, 1 << 18);
      expect(EuiccRspCapability.osUpdateSupport, 1 << 19);
      expect(EuiccRspCapability.cancelForEmptySpnPnSupport, 1 << 20);
      expect(EuiccRspCapability.updateNotifConfigInfoSupport, 1 << 21);
      expect(EuiccRspCapability.updateMetadataV3Support, 1 << 22);
      expect(EuiccRspCapability.v3ObjectsInCtxParamsCASupport, 1 << 23);
      expect(EuiccRspCapability.pushServiceRegistrationSupport, 1 << 24);
    });

    test('LpaRspCapability bit indices match the spec', () {
      expect(LpaRspCapability.crlStaplingV3Support, 1 << 0);
      expect(LpaRspCapability.certChainV3Support, 1 << 1);
      expect(LpaRspCapability.apduApiSupport, 1 << 2);
      expect(LpaRspCapability.enterpriseCapableDevice, 1 << 3);
      expect(LpaRspCapability.lpaProxySupport, 1 << 4);
      expect(LpaRspCapability.signedSmdsResponseV3Support, 1 << 5);
      expect(LpaRspCapability.euiccCiUpdateSupport, 1 << 6);
      expect(LpaRspCapability.eventCheckingSupport, 1 << 7);
      expect(LpaRspCapability.pushServiceSupport, 1 << 8);
      expect(LpaRspCapability.pendingOperationAlertingSupport, 1 << 9);
    });

    test('UICCCapability bit indices match ETSI/SGP.22 ordering', () {
      expect(UICCCapability.contactlessSupport, 1 << 0);
      expect(UICCCapability.usimSupport, 1 << 1);
      expect(UICCCapability.isimSupport, 1 << 2);
      expect(UICCCapability.csimSupport, 1 << 3);
      expect(UICCCapability.akaMilenage, 1 << 4);
      expect(UICCCapability.javacard, 1 << 14);
      expect(UICCCapability.multipleUsimSupport, 1 << 16);
      expect(UICCCapability.s16mode, 1 << 29);
    });

    test('EUICCInfo2_treProperties bit indices match the spec', () {
      expect(EUICCInfo2_treProperties.isDiscrete, 1 << 0);
      expect(EUICCInfo2_treProperties.isIntegrated, 1 << 1);
      expect(EUICCInfo2_treProperties.usesRemoteMemory, 1 << 2);
    });

    test('toString lists every set named bit, pipe separated', () {
      expect(
        NotificationEvent(
          NotificationEvent.notificationInstall |
              NotificationEvent.notificationRpmDelete,
        ).toString(),
        'NotificationEvent.notificationInstall | '
        'NotificationEvent.notificationRpmDelete',
      );
      expect(PprIds(PprIds.ppr1).toString(), 'PprIds.ppr1');
      expect(
        EuiccRspCapability(525).toString(),
        'EuiccRspCapability.additionalProfile | '
        'EuiccRspCapability.rpmSupport | '
        'EuiccRspCapability.testProfileSupport | '
        'EuiccRspCapability.enterpriseProfilesSupport',
      );
    });

    test('toString is empty for zero', () {
      expect(NotificationEvent(0).toString(), '');
      expect(LpaRspCapability(0).toString(), '');
      expect(PprIds(0).toString(), '');
    });

    test('toString falls back to hex when only unknown bits are set', () {
      expect(LpaRspCapability(1 << 20).toString(), '0x100000');
      expect(PprIds(1 << 7).toString(), '0x80');
    });

    test('QUIRK: unknown bits are dropped when a known bit is also set', () {
      expect(
        PprIds(PprIds.ppr1 | (1 << 7)).toString(),
        'PprIds.ppr1', // the 0x80 bit vanishes from the output
      );
    });
  });

  group('BIT STRING wire encoding', () {
    test('round-trips a multi-octet BIT STRING through EUICCInfo2', () {
      const capability =
          EuiccRspCapability.additionalProfile |
          EuiccRspCapability.certChainV3VerificationSupport;

      // The mandatory prefix has to be present or the positional decoder
      // mis-assigns the BIT STRING (see the EUICCInfo2 QUIRK test above).
      final encoded = EUICCInfo2(
        baseProfilePackageVersion: fromHex('020200'),
        lowestSvn: fromHex('020200'),
        euiccFirmwareVersion: fromHex('050001'),
        extCardResource: ExtendedCardResource(installedApplication: 1),
        uiccCapability: UICCCapability(1),
        euiccRspCapability: EuiccRspCapability(capability),
      ).encode();

      // Named bits 0 and 16 => 3 data octets and 7 unused bits: '07 80 00 80'.
      final child = Asn1Reader(
        encoded,
      ).readNext()!.children.firstWhere((c) => c.tag == 0x88);
      expect(toHex(child.value), '07800080');

      final decoded = EUICCInfo2.decode(encoded);
      expect(decoded.euiccRspCapability!.value, capability);
    });

    test('an all-zero BIT STRING encodes as 00 00 and decodes back to 0', () {
      final encoded = NotificationMetadata(
        seqNumber: 1,
        profileManagementOperation: NotificationEvent(0),
      ).encode();

      expect(
        toHex(encoded),
        'BF2F07'
        '800101'
        '81020000',
      );
      expect(
        NotificationMetadata.decode(encoded).profileManagementOperation!.value,
        0,
      );
    });

    test(
      'trailing bits beyond the "unused" count are masked off on decode',
      () {
        // '07 FF' declares 7 unused bits, so only named bit 0 is significant.
        final meta = NotificationMetadata.decode(
          fromHex('BF2F 07  80 01 01  81 02 07FF'),
        );
        expect(meta.profileManagementOperation!.value, 1);
      },
    );
  });

  group('cross-cutting decode behaviour', () {
    test('every decoder tolerates a tag mismatch instead of throwing', () {
      // The generated `fromAsn1` checks the tag but the mismatch branch is
      // empty, so the wrong outer tag is silently accepted.
      final resp = GetEuiccChallengeResponse.decode(
        fromHex('BF2D 12 80 10 000102030405060708090A0B0C0D0E0F'),
      );

      expect(toHex(resp.euiccChallenge!), '000102030405060708090A0B0C0D0E0F');
      // The original (wrong) tag is preserved on re-encode.
      expect(toHex(resp.encode()).startsWith('BF2D'), isTrue);
    });

    test('decode ignores trailing bytes after the first TLV', () {
      final resp = GetEuiccChallengeResponse.decode(
        fromHex('${challengeHex}9000'),
      );

      expect(toHex(resp.euiccChallenge!), '000102030405060708090A0B0C0D0E0F');
      expect(toHex(resp.encode()), normHex(challengeHex));
    });

    test('decode of a non-Uint8List, non-Asn1Node argument is empty', () {
      final resp = GetEuiccChallengeResponse.decode('not bytes');
      expect(resp.euiccChallenge, isNull);
      expect(resp.asn1, isNull);
    });

    test(
      'a decoded value keeps its source node for byte-perfect re-encoding',
      () {
        final profile = ProfileInfo.decode(fromHex(profileInfoHex));
        expect(profile.asn1, isNotNull);
        expect(profile.asn1!.tag, 0xE3);
        expect(toHex(profile.asn1!.encodedBytes), normHex(profileInfoHex));
      },
    );

    test('a hand-built value has no source node', () {
      expect(ProfileInfo(profileName: 'x').asn1, isNull);
    });

    test('non-minimal length encodings survive a decode/encode round trip', () {
      // '81 12' is a valid but non-minimal long-form length for 18 bytes.
      const nonMinimal = 'BF2E 81 12 80 10 000102030405060708090A0B0C0D0E0F';
      final resp = GetEuiccChallengeResponse.decode(fromHex(nonMinimal));

      expect(toHex(resp.euiccChallenge!), '000102030405060708090A0B0C0D0E0F');
      expect(toHex(resp.encode()), normHex(nonMinimal));
      // A freshly built value would use the minimal form instead.
      expect(
        toHex(
          GetEuiccChallengeResponse(
            euiccChallenge: resp.euiccChallenge,
          ).encode(),
        ),
        normHex(challengeHex),
      );
    });
  });

  group('INTEGER encoding helpers (via generated types)', () {
    Uint8List intBytes(int value) {
      final encoded = ProfileInfo(profileSize: value).encode();
      return Asn1Reader(encoded).readNext()!.children.single.value;
    }

    test('encodes small positive integers minimally', () {
      expect(toHex(intBytes(0)), '00');
      expect(toHex(intBytes(1)), '01');
      expect(toHex(intBytes(127)), '7F');
    });

    test('keeps a leading 00 when the high bit would look negative', () {
      expect(toHex(intBytes(128)), '0080');
      expect(toHex(intBytes(255)), '00FF');
      expect(toHex(intBytes(256)), '0100');
      expect(toHex(intBytes(312500)), '04C4B4');
    });

    test('encodes negative integers in two-s complement', () {
      expect(toHex(intBytes(-1)), 'FF');
      expect(toHex(intBytes(-128)), '80');
      expect(toHex(intBytes(-129)), 'FF7F');
    });

    test('decodes signed integers back', () {
      int decodeSize(String hex) =>
          ProfileInfo.decode(fromHex(hex)).profileSize!;

      expect(decodeSize('E3 04 9F25 01 7F'), 127);
      expect(decodeSize('E3 05 9F25 02 0080'), 128);
      expect(decodeSize('E3 04 9F25 01 FF'), -1);
      expect(decodeSize('E3 06 9F25 03 04C4B4'), 312500);
    });
  });
}
