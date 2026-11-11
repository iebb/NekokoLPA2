# ASN.1 → Dart code generation

`lib/models/asn1/rsp_definitions.g.dart` is generated from the ASN.1 modules in
`tools/asn1/` by [asn1_codegen](https://pub.dev/packages/asn1_codegen), which
also provides the runtime the generated code imports
(`package:asn1_codegen/runtime.dart`). Regenerate it with:

```bash
dart run asn1_codegen -o lib/models/asn1/rsp_definitions.g.dart \
  tools/asn1/PKIXExplicit88.asn1 tools/asn1/PKIXImplicit88.asn1 \
  tools/asn1/PEDefinitions.asn1 tools/asn1/RSPDefinitions.asn1 \
  tools/asn1/Supplementary.asn1
```

The module order matters only where two modules define the same name: the
later one wins.

## Files

| File | Role |
| --- | --- |
| `asn1/*.asn1` | The specs: SGP.22 (`RSPDefinitions`), TCA eUICC Profile Package (`PEDefinitions`), RFC 5280 (`PKIX1Explicit88`, `PKIX1Implicit88`), plus `Supplementary` |
| `asn1_format.py` | Whitespace hygiene for the `.asn1` sources |
| `euicc_probe.py` | Read-only ES10 capture from a card in a PC/SC reader |
| `euicc_exchange.py` | Sends a scripted list of ES10 requests; not read-only |

`Supplementary.asn1` holds types that SGP.22 references but defines elsewhere —
`ExtendedCardResource` (ETSI TS 102 226) and `RefArDo`/`ProprietaryTag`
(GlobalPlatform SEAC).

## Naming

Anonymous types are flattened and named by their path, so an inline SEQUENCE at
`RpmCommand.rpmCommandDetails.enable` becomes
`RpmCommand_rpmCommandDetails_enable`, and the element of a `SEQUENCE OF` an
inline type gets an `__item_` suffix. Hyphens become underscores. These names
are part of the public API — changing them breaks callers in `lib/`.

## Checking

```bash
dart run asn1_codegen --check -o lib/models/asn1/rsp_definitions.g.dart \
  tools/asn1/PKIXExplicit88.asn1 tools/asn1/PKIXImplicit88.asn1 \
  tools/asn1/PEDefinitions.asn1 tools/asn1/RSPDefinitions.asn1 \
  tools/asn1/Supplementary.asn1        # is the checked-in Dart up to date?
python3 tools/asn1_format.py --check   # are the .asn1 sources tidy?
flutter test test/models/asn1/         # behaviour of the generated code
dart run test/models/asn1/asn1_benchmark.dart   # decode/encode timings
```

`--check` compares declaration by declaration after `dart format`, so pure
layout differences are ignored.

`asn1_format.py` only normalises whitespace. It does not reindent: these
modules follow three different house styles, and reindenting by brace depth
flattened the hanging indents in SGP.22 and the comment alignment carried over
from the PKIX RFCs.

## Reading

`Asn1Reader` is strict: input that ends early, inside an element or its
length octets, throws a `FormatException` rather than being read as far as it
goes. `Asn1Reader(bytes, lenient: true)` reads what there is.

SEQUENCE members are found by their tags, not by position, which also
tolerates the unknown elements `EXTENSIBILITY IMPLIED` invites. Matching
ignores the constructed bit: X.680 requires the members of a SEQUENCE to have
distinct tag *numbers*, so it cannot be ambiguous, and cards do disagree with
the schema about it — `EUICCInfo2.extCardResource` arrives as a primitive `84`
although its content is constructed.

Strings are read one character per octet; `profile_manager.dart` turns the
UTF-8 ones into text with `utf8.decode(s.codeUnits)`.
