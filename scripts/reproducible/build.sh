#!/usr/bin/env bash
set -euo pipefail
umask 022
export HOME=/root PUB_CACHE=/root/.pub-cache
mkdir -p /workspace
cd /workspace
# Input is a Git archive, so no private overlay, local config or GitHub token
# can enter the build. Every independent run starts in a new container.
tar -xf -
test ! -e android/key.properties
test ! -e scripts/build_variants.json
test ! -e scripts/flavors.json
export SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:?Missing source epoch}"
export GRADLE_OPTS='-Dorg.gradle.daemon=false -Dorg.gradle.workers.max=2 -Dfile.encoding=UTF-8 -Duser.timezone=UTC'
flutter pub get --enforce-lockfile
cargo fetch --locked --manifest-path rust/Cargo.toml
args=(--release --flavor "$1" --target lib/main.dart --no-pub --dart-define=GM_PSK_URL=https://key.9esim.com/psk)
if [ "$1" = privileged ]; then
    args+=(--target-platform android-arm64 --dart-define=PRIVILEGED_BUILD=true --dart-define=APP_VARIANT=community-rooted)
else
    args+=(--dart-define=APP_VARIANT=community)
fi
flutter build apk "${args[@]}"
apk="build/app/outputs/flutter-apk/app-$1-release.apk"
"$ANDROID_HOME/build-tools/36.0.0/apksigner" verify --verbose --print-certs "$apk" > /out/signer.txt
cp "$apk" /out/community.apk
if [ -n "${OUTPUT_UID:-}" ]; then chown "$OUTPUT_UID:${OUTPUT_GID:-$OUTPUT_UID}" /out/community.apk /out/signer.txt; fi
