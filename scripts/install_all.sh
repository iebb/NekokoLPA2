#!/bin/bash

# Simple script to install all generated APKS to a connected device

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APK_DIR="$REPO_ROOT/release_apks"

if [ ! -d "$APK_DIR" ]; then
    echo "Error: Release directory not found at $APK_DIR"
    exit 1
fi

echo "Searching for APKS in $APK_DIR..."

# Avoid signature conflicts by uninstalling old variants with same package IDs
# Note: Rebranded APKs might share IDs or have their own.
adb uninstall ee.nekoko.nlpa2.std
adb uninstall ee.nekoko.nlpa2.multi
adb uninstall ee.nekoko.nlpa2.sekiu
adb uninstall ee.nekoko.nlpa2 # legacy

# We want these specific variants
VARIANTS=(
    "app-privileged-release.apk"
    "app-normal-release.apk"
    "app-m-release.apk"
    "app-sekiu-release.apk"
)

for v in "${VARIANTS[@]}"; do
    apk="$APK_DIR/$v"
    if [ -f "$apk" ]; then
        echo "--- Installing $v ---"
        adb install -r "$apk"
    else
        echo "Warning: $v not found"
    fi
done

echo "Done!"
