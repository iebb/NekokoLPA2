#!/usr/bin/env python3
"""Render artifact metadata with live certificate fingerprints and no inline passwords."""
import argparse
import json
from pathlib import Path
import re
import shutil
import subprocess
from signing_credentials import password_environment


def keytool_sha1(keystore, store_type=None):
    keytool = shutil.which("keytool")
    if not keytool or not keystore.is_file():
        return []
    command = [keytool, "-list", "-keystore", str(keystore),
               "-storepass:env", password_environment(keystore), "-v"]
    if store_type:
        command += ["-storetype", store_type]
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode:
        return []
    return [value.replace(":", "").upper() for value in re.findall(r"SHA1:\s*([0-9A-Fa-f:]+)", result.stdout)]


def render(config, root):
    cache = {name: keytool_sha1(root / entry["keystore"], entry.get("store_type"))
             for name, entry in config["keys"].items()}
    print("| Package / Artifact | Platform | ARAM SHA-1 | Description |")
    print("| --- | --- | --- | --- |")
    for package, platform, keys, description in config["variants"]:
        signatures = [value for key in keys for value in cache.get(key, [])]
        cell = "<br>".join(f"`{value}`" for value in signatures) if signatures else "_(keystore unavailable)_"
        print(f"| `{package}` | {platform} | {cell} | {description} |")
    for package, platform, description in config.get("desktop", []):
        print(f"| `{package}` | {platform} | — | {description} |")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, required=True, help="Non-secret artifact manifest")
    parser.add_argument("--root", type=Path, default=Path.cwd())
    args = parser.parse_args()
    render(json.loads(args.config.read_text()), args.root)


if __name__ == "__main__":
    main()
