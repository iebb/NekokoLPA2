# Translations

NekokoLPA 2 is translated on [Crowdin](https://crowdin.com/project/nekokolpa2).
Only edit `l10n/app_en.arb` by hand. Crowdin owns the other nine ARB files;
Flutter generates `lib/l10n/`. Missing translations fall back to English.

## Contributor workflow

1. Add or change English messages and placeholder metadata in `l10n/app_en.arb`.
2. Run `flutter gen-l10n` and `python3 scripts/check_l10n.py` from this repository.
3. Push to `master`. [Crowdin Sync](.github/workflows/crowdin_sync.yml) detects
   English changes, uploads the existing Crowdin source file, downloads all nine
   locales, regenerates localizations and commits them directly to this repository.

No Kasutera pointer move or private GitHub token is needed. The workflow uses
this repository's encrypted `CROWDIN_TOKEN` and its scoped `GITHUB_TOKEN` for
commits. It also downloads translations every Monday at 03:17 UTC and supports
manual dispatch with `upload_source=true`.

The single Crowdin project is `876432`; source file ID `5` remains
`l10n/app.arb`. This migration reuses that file and its translations. Do not add
a second source or a parallel GitHub integration, which would duplicate strings.

## Translators

Use the Crowdin editor, choose your language and open `l10n/app.arb`. Preserve
placeholders such as `{count}` and identifiers such as ICCID, EID and SM-DP+.
Translations are downloaded on the next sync; do not hand-edit locale ARBs.

## Local sync

Set `CROWDIN_TOKEN` in the environment, then run:

```sh
python3 scripts/crowdin_sync.py --upload-source
```

Omit the option to download only. The offline validator rejects duplicate English
keys and locale keys absent from the English source. It does not require tokens.
