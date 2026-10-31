# Shared build and release tools

Application behavior and shared build/release implementations are maintained in NekokoLPA2. A branding overlay can provide data files without replacing the shared engine:

| Public implementation | Optional overlay data |
| --- | --- |
| `scripts/build.py` | `scripts/build_variants.json`, or `NLPA_BUILD_VARIANTS_FILE` |
| `scripts/prepare_flavor.py` | `scripts/flavors.json`, or `NLPA_FLAVORS_FILE` |
| `scripts/generate_release_table.py` | Artifact manifest passed with `--config` and keystore root passed with `--root` |
| `scripts/signing_credentials.py` | CI credentials JSON or an ignored, protected local file |
| `scripts/android_lineage.py` | Explicit key-chain manifest, keys and rotation proof |
| `scripts/play_store_submission.py` | Explicit `--target package=/path/app.aab` and an untracked service-account file |

Brand manifests hold package IDs, display names, icon paths and keystore filenames. Passwords do not belong in them. The lineage implementation and tests are described in [the signing guide](android-lineage.md).

The Windows installer helpers, icon-copy utilities, Bluetooth diagnostic and temporary Play-credential helper are also public under `scripts/`. `scripts/installer.iss` retains the existing private publisher's installer identity; the standard public release continues using `installer/installer.iss`. This preserves both existing installation paths during the source migration.

The build engine's branding routes expect the relevant Gradle/Xcode overlay projects. A plain public checkout builds the app directly with Flutter, or uses the self-contained Community entry points:

```sh
python3 scripts/build.py community android
# "open" is a compatibility alias; "community-rooted" and "open-rooted" select the rooted APK.
```

Those Community entry points invoke [the reproducible recipe](reproducible-community.md) and do not load private signing credentials or brand configuration into the build container. Public desktop/web builds use the normal Flutter build commands and the NekokoLPA 2 name.

The update/config backend source, schema, local tests and development configs are in [services/update-service](../services/update-service/README.md). Deployment settings can remain in an operator's private repository.
