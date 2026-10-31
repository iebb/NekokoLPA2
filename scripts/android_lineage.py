"""Create a rotation chain once, then sign experimental APKs with its leaf key.

Passwords are passed to apksigner through child-process environment variables.
The lineage contains public certificates and proofs, never private keys.
"""

import argparse
from dataclasses import dataclass, field
import json
import os
from pathlib import Path
import subprocess
import tempfile


def find_apksigner():
    explicit = os.environ.get("NLPA_APKSIGNER_JAR")
    if explicit:
        return Path(explicit)
    # Release overlays keep the same keys and bundled signer beside the app.
    legacy = Path(__file__).resolve().parents[2] / "signer/apksigner.jar"
    if legacy.is_file():
        return legacy
    sdk = Path(os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT") or Path.home() / "Library/Android/sdk")
    candidates = list((sdk / "build-tools").glob("*/lib/apksigner.jar"))
    def version(path):
        return tuple(int(part) if part.isdigit() else 0 for part in path.parents[1].name.split('.'))
    return max(candidates, key=version) if candidates else legacy

DEFAULT_APKSIGNER = find_apksigner()


@dataclass(frozen=True)
class Signer:
    keystore: Path
    password: str = field(repr=False)
    alias: str | None = None
    key_password: str | None = field(default=None, repr=False)
    store_type: str | None = None

    def arguments(self, prefix, environment):
        environment[prefix + "_STORE_PASSWORD"] = self.password
        arguments = ["--ks", str(self.keystore), "--ks-pass", "env:" + prefix + "_STORE_PASSWORD"]
        if self.alias:
            arguments += ["--ks-key-alias", self.alias]
        if self.key_password is not None:
            environment[prefix + "_KEY_PASSWORD"] = self.key_password
            arguments += ["--key-pass", "env:" + prefix + "_KEY_PASSWORD"]
        if self.store_type:
            arguments += ["--ks-type", self.store_type]
        return arguments


def run(apksigner, arguments, environment):
    subprocess.run(["java", "-jar", str(apksigner), *arguments], env=environment, check=True)


def create_lineage(signers, output, apksigner=DEFAULT_APKSIGNER):
    output = Path(output)
    if len(signers) < 2:
        raise ValueError("A lineage requires at least two signers")
    if output.exists():
        raise ValueError("Refusing to replace an existing lineage")
    for signer in signers:
        if not signer.keystore.is_file():
            raise ValueError(f"Keystore does not exist: {signer.keystore}")
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="lineage-", dir=output.parent) as temporary:
        previous = None
        for index, (old, new) in enumerate(zip(signers, signers[1:])):
            current = Path(temporary) / f"rotation-{index}.lineage"
            environment = os.environ.copy()
            arguments = ["rotate", "--out", str(current)]
            if previous is not None:
                arguments += ["--in", str(previous)]
            arguments += ["--old-signer", *old.arguments("NLPA_OLD", environment)]
            arguments += ["--new-signer", *new.arguments("NLPA_NEW", environment)]
            run(apksigner, arguments, environment)
            previous = current
        # Link rather than replace so a concurrent creator cannot overwrite it.
        os.link(previous, output)
    print(f"Created {output} with {len(signers)} signing certificates")


def sign_apk(apk, output, lineage, signer, apksigner=DEFAULT_APKSIGNER):
    apk, output, lineage = Path(apk), Path(output), Path(lineage)
    if not lineage.is_file():
        raise ValueError(f"Signing lineage is missing: {lineage}")
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="lineage-sign-", dir=output.parent) as temporary:
        signed = Path(temporary) / "signed.apk"
        environment = os.environ.copy()
        arguments = [
            "sign", "--in", str(apk), "--out", str(signed),
            "--lineage", str(lineage), "--min-sdk-version", "28",
            "--rotation-min-sdk-version", "28",
            # v1/v2 require the oldest private key. This separate Android 9+
            # package intentionally uses v3 only, so CI only needs the leaf.
            "--v1-signing-enabled", "false", "--v2-signing-enabled", "false",
            "--v3-signing-enabled", "true", "--v4-signing-enabled", "false",
            *signer.arguments("NLPA_LEAF", environment),
        ]
        run(apksigner, arguments, environment)
        run(apksigner, ["verify", "--min-sdk-version", "28", str(signed)], environment)
        os.replace(signed, output)
    print(f"Signed and verified {output} (Android 9+, v3 rotation)")


def legacy_multi_signers():
    from signing_credentials import signing_password
    manifest = Path(os.environ.get("NLPA_BUILD_VARIANTS_FILE", str(Path(__file__).parent / "build_variants.json")))
    records = json.loads(manifest.read_text())
    config = next(value for value in records if value["suffix"] == "multi")
    overlay_root = Path(os.environ.get("NLPA_OVERLAY_ROOT", str(Path(__file__).resolve().parents[2])))
    return [Signer(overlay_root / value["ks"], signing_password(value["ks"])) for value in config["key_configs"]]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apksigner", type=Path, default=DEFAULT_APKSIGNER)
    commands = parser.add_subparsers(dest="command", required=True)
    create = commands.add_parser("create", help="One-time rotation ceremony with all keys")
    source = create.add_mutually_exclusive_group(required=True)
    source.add_argument("--legacy-multi", action="store_true", help="Use the existing M keys, in their configured order")
    source.add_argument("--config", type=Path, help="JSON array of keystore, password_env, optional alias/key_password_env/store_type")
    create.add_argument("--out", type=Path, required=True)
    sign = commands.add_parser("sign", help="CI signing with only the leaf key")
    sign.add_argument("--in", dest="apk", type=Path, required=True)
    sign.add_argument("--out", type=Path, required=True)
    sign.add_argument("--lineage", type=Path, required=True)
    sign.add_argument("--ks", type=Path, required=True)
    sign.add_argument("--password-env", default="NLPA_LINEAGE_STORE_PASSWORD")
    sign.add_argument("--key-password-env")
    sign.add_argument("--alias")
    sign.add_argument("--store-type")
    args = parser.parse_args()
    try:
        if args.command == "create":
            if args.legacy_multi:
                signers = legacy_multi_signers()
            else:
                records = json.loads(args.config.read_text())
                signers = [Signer(
                    (args.config.parent / record["keystore"]).resolve(),
                    os.environ[record["password_env"]], record.get("alias"),
                    os.environ[record["key_password_env"]] if record.get("key_password_env") else None,
                    record.get("store_type"),
                ) for record in records]
            create_lineage(signers, args.out, args.apksigner)
        else:
            signer = Signer(args.ks, os.environ[args.password_env], args.alias,
                            os.environ[args.key_password_env] if args.key_password_env else None,
                            args.store_type)
            sign_apk(args.apk, args.out, args.lineage, signer, args.apksigner)
    except (ValueError, KeyError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Lineage operation failed: {error}\n")


if __name__ == "__main__":
    main()
