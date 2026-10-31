#!/usr/bin/env bash
# Compatibility entry point for the shared Android build engine.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$SCRIPT_DIR/build.py" "${1:?Usage: build_android_variant.sh VARIANT}" android
