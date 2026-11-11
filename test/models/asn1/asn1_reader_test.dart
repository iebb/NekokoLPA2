import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:asn1_codegen/runtime.dart';

import 'asn1_hex.dart';

/// Behavioural tests for the TLV reader that the generated SGP.22 model code
/// is built on (`Asn1Reader` from `package:asn1_codegen/runtime.dart`).
///
/// These pin *observable* behaviour only: tag values, value bytes, child
/// splitting and `encodedBytes`, as the app relies on them.
void main() {
  group('Asn1Reader single-byte tags', () {
    test('reads tag, value and the exact source bytes of one TLV', () {
      // OCTET STRING (universal 4), 3 bytes of content.
      final node = Asn1Reader(fromHex('04 03 AABBCC')).readNext()!;

      expect(node.tag, 0x04);
      expect(toHex(node.value), 'AABBCC');
      expect(toHex(node.encodedBytes), '0403AABBCC');
      expect(node.isTag(0x04), isTrue);
      expect(node.isTag(0x05), isFalse);
    });

    test('walks consecutive TLVs until hasMore goes false', () {
      final reader = Asn1Reader(fromHex('800101 810102 820103'));

      final tags = <int>[];
      while (reader.hasMore) {
        tags.add(reader.readNext()!.tag);
      }

      expect(tags, [0x80, 0x81, 0x82]);
      expect(reader.readNext(), isNull);
    });

    test('returns null for empty input', () {
      expect(Asn1Reader(Uint8List(0)).readNext(), isNull);
      expect(Asn1Reader(Uint8List(0)).hasMore, isFalse);
    });

    test('reads a zero-length value', () {
      // GetEuiccChallengeRequest on the wire: BF2E 00.
      final node = Asn1Reader(fromHex('BF2E00')).readNext()!;

      expect(node.tag, 0xBF2E);
      expect(node.value, isEmpty);
      expect(toHex(node.encodedBytes), 'BF2E00');
    });
  });

  group('Asn1Reader multi-byte tags', () {
    // SGP.22 uses high-tag-number form all over the place; the reader folds
    // the tag octets into a single int, big-endian, e.g. 'BF 2D' -> 0xBF2D.
    test('folds two-byte context tags into one int', () {
      expect(Asn1Reader(fromHex('BF2E00')).readNext()!.tag, 0xBF2E);
      expect(Asn1Reader(fromHex('BF2D00')).readNext()!.tag, 0xBF2D);
      expect(Asn1Reader(fromHex('BF2200')).readNext()!.tag, 0xBF22);
      expect(Asn1Reader(fromHex('BF2F00')).readNext()!.tag, 0xBF2F);
      expect(Asn1Reader(fromHex('BF3700')).readNext()!.tag, 0xBF37);
    });

    test('handles the ProfileInfo private/context tags 9F70, 9F24, 9F25', () {
      expect(Asn1Reader(fromHex('9F70 01 01')).readNext()!.tag, 0x9F70);
      expect(Asn1Reader(fromHex('9F24 01 00')).readNext()!.tag, 0x9F24);
      expect(Asn1Reader(fromHex('9F25 01 05')).readNext()!.tag, 0x9F25);
    });

    test('handles the application tag 5F37 (EuiccSign)', () {
      final node = Asn1Reader(fromHex('5F37 02 ABCD')).readNext()!;
      expect(node.tag, 0x5F37);
      expect(toHex(node.value), 'ABCD');
    });

    test('keeps consuming tag octets while the continuation bit is set', () {
      // 'BF 81 2E' is a three-octet tag; the reader folds all three.
      final node = Asn1Reader(fromHex('BF812E 00')).readNext()!;
      expect(node.tag, 0xBF812E);
    });

    test('a multi-byte tag does not confuse the following TLV', () {
      final reader = Asn1Reader(fromHex('9F70 01 01 90 02 4142'));
      expect(reader.readNext()!.tag, 0x9F70);
      final second = reader.readNext()!;
      expect(second.tag, 0x90);
      expect(toHex(second.value), '4142');
      expect(reader.hasMore, isFalse);
    });
  });

  group('Asn1Reader length forms', () {
    test('reads short-form lengths', () {
      final node = Asn1Reader(fromHex('04 7F ${'00' * 127}')).readNext()!;
      expect(node.value.length, 127);
    });

    test('reads one-octet long-form lengths (0x81 nn)', () {
      final node = Asn1Reader(fromHex('04 81 C8 ${'00' * 200}')).readNext()!;
      expect(node.value.length, 200);
    });

    test('reads two-octet long-form lengths (0x82 nn nn)', () {
      final node = Asn1Reader(fromHex('04 82 0100 ${'00' * 256}')).readNext()!;
      expect(node.value.length, 256);
    });

    test('rejects a truncated value', () {
      // Declares 10 bytes but only 3 are present.
      expect(
        () => Asn1Reader(fromHex('04 0A AABBCC')).readNext(),
        throwsA(isA<FormatException>()),
      );
    });

    test('a lenient reader clamps a truncated value instead', () {
      final node = Asn1Reader(
        fromHex('04 0A AABBCC'),
        lenient: true,
      ).readNext()!;
      expect(toHex(node.value), 'AABBCC');
      expect(toHex(node.encodedBytes), '040AAABBCC');
    });

    test('reads indefinite length up to the end-of-contents octets', () {
      final node = Asn1Reader(fromHex('30 80 040100 0000')).readNext()!;
      expect(node.tag, 0x30);
      expect(toHex(node.value), '040100');
      expect(node.children.single.tag, 0x04);
    });

    test('rejects truncated length octets', () {
      expect(
        () => Asn1Reader(fromHex('04')).readNext(),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => Asn1Reader(fromHex('04 82 01')).readNext(),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('Asn1Node.children', () {
    test('splits a constructed value into child TLVs', () {
      // ProfileInfoListResponse-ish: A0 wrapping two E3 elements.
      final node = Asn1Reader(
        fromHex('A0 0A E3 02 5A00 E3 04 5A02 AABB'),
      ).readNext()!;

      final children = node.children;
      expect(children.length, 2);
      expect(children[0].tag, 0xE3);
      expect(children[1].tag, 0xE3);
      expect(toHex(children[1].children.single.value), 'AABB');
    });

    test('children of a primitive value are best-effort, not empty', () {
      // QUIRK: `children` re-parses whatever bytes are in `value`; it does not
      // check the constructed bit first. An OCTET STRING whose content happens
      // to look like a TLV therefore yields "children".
      final node = Asn1Reader(fromHex('04 03 040100')).readNext()!;
      expect(node.children.length, 1);
      expect(node.children.single.tag, 0x04);
    });

    test('children is empty for an empty value', () {
      final node = Asn1Reader(fromHex('30 00')).readNext()!;
      expect(node.children, isEmpty);
    });

    test('each child keeps its own exact source bytes', () {
      final node = Asn1Reader(fromHex('30 06 800101 810102')).readNext()!;
      expect(toHex(node.children[0].encodedBytes), '800101');
      expect(toHex(node.children[1].encodedBytes), '810102');
    });
  });

  group('Asn1Node.encodedBytes without source bytes', () {
    test('re-encodes a single-byte tag with a short-form length', () {
      final node = Asn1Node(0x80, fromHex('AABBCC'));
      expect(toHex(node.encodedBytes), '8003AABBCC');
    });

    test('re-encodes with a long-form length past 127 bytes', () {
      final node = Asn1Node(0x04, Uint8List(200));
      final encoded = node.encodedBytes;
      expect(toHex(encoded.sublist(0, 3)), '0481C8');
      expect(encoded.length, 3 + 200);
    });

    test('re-encodes a multi-byte tag as its identifier octets', () {
      final node = Asn1Node(0xBF2E, fromHex('AA'));
      expect(toHex(node.encodedBytes), 'BF2E01AA');
      expect(toHex(Asn1Node(0x9F70, fromHex('01')).encodedBytes), '9F700101');
    });

    test('a node from the reader returns the original bytes verbatim', () {
      // This is what makes the generated `encode()` byte-perfect: it hands back
      // `asn1.encodedBytes`, which is the untouched source slice - including a
      // non-minimal length encoding.
      final node = Asn1Reader(fromHex('04 81 03 AABBCC')).readNext()!;
      expect(toHex(node.encodedBytes), '048103AABBCC');
    });
  });

  group('Asn1Node.prettyPrint', () {
    test('labels known universal tags and renders nested structure', () {
      final node = Asn1Reader(fromHex('30 07 020101 04024142')).readNext()!;
      final text = node.prettyPrint();

      expect(text, contains('SEQUENCE (0x30)'));
      expect(text, contains('INTEGER (0x2)'));
      expect(text, contains('OCTET STRING (0x4)'));
      expect(text, contains('"AB"')); // 41 42 renders as printable text
      expect(node.toString(), text);
    });

    test('labels context/private tags by class', () {
      final node = Asn1Reader(fromHex('BF2E 02 AABB')).readNext()!;
      expect(node.prettyPrint(), contains('[Context 0xBF2E]'));

      final priv = Asn1Reader(fromHex('E3 02 AABB')).readNext()!;
      expect(priv.prettyPrint(), contains('[Private 0xE3]'));
    });

    test('marks an empty primitive value as [Empty]', () {
      expect(
        Asn1Reader(fromHex('8000')).readNext()!.prettyPrint(),
        contains('[Empty]'),
      );
    });

    test('renders an empty constructed value as an empty block', () {
      // QUIRK: a zero-length *constructed* node (e.g. GetEuiccChallengeRequest
      // 'BF2E 00') is not labelled [Empty]; it prints as an empty child block.
      final text = Asn1Reader(fromHex('BF2E00')).readNext()!.prettyPrint();
      expect(text, contains('(0 bytes) {'));
      expect(text, isNot(contains('[Empty]')));
    });

    test('truncates long hex dumps', () {
      final node = Asn1Reader(fromHex('04 81 C8 ${'AB' * 200}')).readNext()!;
      final text = node.prettyPrint();
      expect(text, contains('[200 bytes]'));
      expect(text, contains('...'));
    });

    test('indents nested nodes by two spaces per level', () {
      final node = Asn1Reader(fromHex('30 04 04024142')).readNext()!;
      expect(node.prettyPrint(), contains('\n  OCTET STRING'));
    });
  });
}
