# Secret-free, reproducible Community builds

Community is the current name for the public Android build previously called Open. Its package identity and signing certificate remain compatible. Both the normal and rooted public builds use `android/app/community.jks` and its intentionally public password. Public Gradle configuration ignores local signing properties and private signing environment variables.

A clean public checkout needs no Kasutera repository, signing Secret, API token or Google/Apple account to build Community.

## Build and compare

Install Python 3, Git and Docker. From a public checkout containing this recipe:

```sh
python3 scripts/reproduce_community.py --ref HEAD --verify
python3 scripts/reproduce_community.py --ref HEAD --variant privileged --verify --output dist/rooted
```

`--ref` selects a committed source revision or a future release tag containing this recipe. Uncommitted files and private overlays are excluded. The script loads the Docker recipe from that same revision, feeds only a Git archive into each container and mounts only an output directory. It does not forward host signing variables or GitHub credentials.

`--verify` creates two independent containers and fails unless the signed APK bytes match. `build.json` records the commit, source epoch, recipe hash, APK hash and number of compared builds. `signer.txt` records apksigner verification. On a mismatch, both outputs are retained for inspection.

## Pinned inputs

- Public Linux amd64 Flutter/Android and Rust base images are pinned by manifest digest.
- Flutter is pinned to commit `d3b14c876900e553bc736ca19295fc09e3853e8e` (3.47.2).
- The JDK and Android command-line tools come from the pinned base image.
- Android platform 36, build-tools 36.0.0 and NDK 28.2.13676358 are selected explicitly.
- Rust is pinned to 1.99.1, including the Android targets. Cargokit honors that explicit version and uses `--locked`.
- Pub dependencies must match `pubspec.lock`; Cargo dependencies use the committed lockfile.
- Container source/cache paths and locale are fixed. `SOURCE_DATE_EPOCH` comes from the source commit.

The public release workflow uses the same recipe and requires the two-build comparison. The separate **Reproducible Community APKs** workflow can verify a source change without publishing a release. Both build with the public Community key and contain no repository-secret references.

Ordinary `flutter build apk --release --flavor community --dart-define=APP_VARIANT=community` remains available without Secrets. Byte-for-byte comparison uses the pinned container recipe. Releases made before this recipe, including 2.4.2+602, are not retroactively claimed to match it.
