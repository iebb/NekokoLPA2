from signing_credentials import password_environment, prepare_android_properties, signing_password

import os
import json
import sys
import subprocess
import shutil
from pathlib import Path


# Configuration for flavors
# Brand-specific recipes are supplied by an optional overlay manifest.
def load_build_variants():
    manifest = Path(os.environ.get("NLPA_BUILD_VARIANTS_FILE", str(Path(__file__).parent / "build_variants.json")))
    if not manifest.is_file():
        return []
    with manifest.open() as stream:
        records = json.load(stream)
    if not isinstance(records, list):
        raise ValueError("Build variant manifest must be a JSON array")
    return records

CONFIG = load_build_variants()


# Determine apksigner path relative to script
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = Path(SCRIPT_DIR).parent
# If running from NekokoLPA2/scripts, signer is in ../../signer
APKSIGNER = os.path.abspath(os.path.join(SCRIPT_DIR, "../../signer/apksigner.jar"))

# Helper to run shell commands
def run_cmd(cmd, cwd=None):
    # The GM card PSK service is configured per build, not kept in the source.
    if cmd[:2] == ["flutter", "build"]:
        cmd = cmd + [f"--dart-define=GM_PSK_URL={os.environ.get('GM_PSK_URL', '')}"]
    safe_cmd = list(cmd)
    for index, value in enumerate(cmd[:-1]):
        if value in ("--ks-pass", "--key-pass"):
            safe_cmd[index + 1] = "[redacted]"
    print(f"Running: {' '.join(safe_cmd)}")
    subprocess.run(cmd, check=True, cwd=cwd)

def find_zipalign():
    # Try finding via local.properties
    sdk_dir = None
    if os.path.exists("android/local.properties"):
        with open("android/local.properties", "r") as f:
            for line in f:
                if line.strip().startswith("sdk.dir="):
                    sdk_dir = line.strip().split("=", 1)[1]
                    break
    
    if not sdk_dir:
        # Fallback to environment variable
        sdk_dir = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")

    if sdk_dir:
        build_tools_dir = os.path.join(sdk_dir, "build-tools")
        if os.path.exists(build_tools_dir):
            versions = sorted(os.listdir(build_tools_dir), reverse=True)
            for v in versions:
                zipalign = os.path.join(build_tools_dir, v, "zipalign")
                if os.path.exists(zipalign):
                    return zipalign
                # Windows might have .exe
                if os.path.exists(zipalign + ".exe"):
                    return zipalign + ".exe"
    
    # Try PATH
    return shutil.which("zipalign")

def update_commit_hash():
    try:
        # Get short commit hash
        result = subprocess.run(["git", "rev-parse", "--short", "HEAD"], capture_output=True, text=True, check=True)
        commit_hash = result.stdout.strip()
        
        version_file = "lib/version.dart"
        if os.path.exists(version_file):
            import re
            with open(version_file, "r") as f:
                content = f.read()
            
            # Replace whatever is in kCommitHash with the real hash
            new_content = re.sub(r"const String kCommitHash = '.*';", f"const String kCommitHash = '{commit_hash}';", content)
            
            if content != new_content:
                print(f"Updating kCommitHash to {commit_hash} in {version_file}")
                with open(version_file, "w") as f:
                    f.write(new_content)
    except Exception as e:
        print(f"Warning: Failed to update commit hash: {e}")

def main():
    if len(sys.argv) < 2 or sys.argv[1] in ("--help", "-h"):
        print("Usage: python3 build.py <variant> [platform]")
        print("Variants: community (open), community-rooted (open-rooted), std, multi, lineage, sekiu, privileged, esim9")

        print("Platforms: android, linux, all (default: all)")
        sys.exit(0 if len(sys.argv) >= 2 else 1)


    variant = sys.argv[1]
    platform = sys.argv[2] if len(sys.argv) > 2 else "all"
    if variant in ("community", "open", "community-rooted", "open-rooted"):
        if platform not in ("android", "all"):
            sys.exit("Community is an Android variant; use flutter build for desktop/web.")
        public_variant = "privileged" if variant.endswith("-rooted") else "community"
        subprocess.run([sys.executable, str(ROOT_DIR / "scripts/reproduce_community.py"),
                        "--variant", public_variant], check=True)
        return
    if platform in ("android", "all"):
        prepare_android_properties(ROOT_DIR, optional=True)
    build_android = platform in ["android", "all"]
    build_linux = platform in ["linux", "all"]

    if variant == "lineage" and build_android:
        lineage_path = Path(os.environ.get(
            "NLPA_SIGNING_LINEAGE", str(Path(APKSIGNER).parent.parent / "signing/multi.lineage")
        ))
        if not lineage_path.is_file():
            sys.exit("Missing signing lineage. Run android_lineage.py create before building the experiment.")
    
    # The app root is the parent of this script's folder (NekokoLPA2/), where
    # the overlay puts it; abspath, not realpath, so a --link symlink counts.
    os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

    update_commit_hash()

    # Read version
    version_line = ""
    with open("pubspec.yaml", "r") as f:
        for line in f:
            if line.startswith("version:"):
                version_line = line.strip()
                break
    
    if not version_line:
        print("Error: Could not find version in pubspec.yaml")
        sys.exit(1)

    version_str = version_line.replace("version: ", "")
    v_name = version_str.split("+")[0]
    v_code = version_str.split("+")[1]
    v_filename = version_str.replace("+", "-")

    release_dir = "release"
    if not os.path.exists(release_dir):
        os.makedirs(release_dir)

    print("=========================================")
    print(f"Building Android Variant: {variant} ({v_name}+{v_code})")
    print("=========================================")

    if variant in ["std", "normal"]:
        if build_android:
            print("Building Android Standard...")
            run_cmd([
                "flutter", "build", "apk", "--release", "--split-per-abi", "--flavor", "normal", 
                "--target-platform", "android-arm64", "--dart-define=APP_VARIANT=std", "--dart-define=ENABLE_ZXING=false",
                "--no-pub", "--obfuscate", "--split-debug-info=release/symbols"
            ])
            apk_src = "build/app/outputs/flutter-apk/app-arm64-v8a-normal-release.apk"
            apk_dest = f"{release_dir}/ee.nekoko.nlpa2.std-{v_filename}-arm64-v8a.apk"
            shutil.copy2(apk_src, apk_dest)
            print(f"✅ Created {apk_dest}")
            
            # Build AAB for Community variant
            print("Building Android Standard AAB...")
            run_cmd([
                "flutter", "build", "appbundle", "--release", "--flavor", "normal", 
                "--dart-define=APP_VARIANT=std", "--dart-define=ENABLE_ZXING=false",
                "--no-pub", "--obfuscate", "--split-debug-info=release/symbols"
            ])
            aab_src = "build/app/outputs/bundle/normalRelease/app-normal-release.aab"
            aab_dest = f"{release_dir}/ee.nekoko.nlpa2.std-{v_filename}.aab"
            shutil.copy2(aab_src, aab_dest)
            print(f"✅ Created {aab_dest}")

        if build_linux:
            # Linux
            print("Building Linux Standard...")
            run_cmd([
                "flutter", "build", "linux", "--release", "--dart-define=APP_VARIANT=std", "--dart-define=ENABLE_ZXING=true",
                "--no-pub"
            ])
            linux_bundle = "build/linux/x64/release/bundle"
            linux_base_name = f"ee.nekoko.nlpa2.linux-{v_filename}"
            package_linux(linux_bundle, release_dir, linux_base_name, variant)

    elif variant in ("multi", "lineage"):
        if build_android:
            flavor = "lineage" if variant == "lineage" else "m"
            channel_args = ["--dart-define=APP_UPDATE_CHANNEL=lineage"] if variant == "lineage" else []
            # Android
            run_cmd([
                "flutter", "build", "apk", "--release", "--split-per-abi", "--flavor", flavor,
                "--target-platform", "android-arm64,android-arm", "--dart-define=APP_VARIANT=multi", "--dart-define=ENABLE_ZXING=false",
                "--no-pub", "--obfuscate", "--split-debug-info=release/symbols"
            ] + channel_args)
            apk_src = f"build/app/outputs/flutter-apk/app-arm64-v8a-{flavor}-release.apk"
            package = "ee.nekoko.nlpa2.multi.lineage" if variant == "lineage" else "ee.nekoko.nlpa2.multi"
            apk_dest = f"{release_dir}/{package}-{v_filename}-arm64-v8a.apk"
            
            apk_src_v7a = f"build/app/outputs/flutter-apk/app-armeabi-v7a-{flavor}-release.apk"
            apk_dest_v7a = f"{release_dir}/{package}-{v_filename}-armeabi-v7a.apk"
            
            # Apply rebranding directly
            print("Applying rebranding (Android)...")
            flavor_conf = next((f for f in CONFIG if f["suffix"] == "multi"), None)
            if flavor_conf:
                 if variant == "lineage":
                     flavor_conf = {**flavor_conf, "lineage": True}
                 rebrand_apk(apk_src, apk_dest, flavor_conf)
                 rebrand_apk(apk_src_v7a, apk_dest_v7a, flavor_conf)
            else:
                 print("Error: Multi config not found")
                 sys.exit(1)

            print(f"✅ Created {apk_dest}")
            print(f"✅ Created {apk_dest_v7a}")

    elif variant == "sekiu":
        if build_android:
            # Android
            run_cmd([
                "flutter", "build", "apk", "--release", "--split-per-abi", "--flavor", "sekiu", 
                "--target-platform", "android-arm64", "--dart-define=APP_VARIANT=sekiu", "--dart-define=ENABLE_ZXING=false",
                "--no-pub", "--obfuscate", "--split-debug-info=release/symbols"
            ])
            apk_src = "build/app/outputs/flutter-apk/app-arm64-v8a-sekiu-release.apk"
            apk_dest = f"{release_dir}/ee.nekoko.nlpa2.sekiu-{v_filename}-arm64-v8a.apk"
            
            # Apply rebranding directly
            print("Applying rebranding (Android)...")
            flavor_conf = next((f for f in CONFIG if f["suffix"] == "sekiu"), None)
            if flavor_conf:
                 rebrand_apk(apk_src, apk_dest, flavor_conf)
            else:
                 print("Error: Sekiu config not found")
                 sys.exit(1)

            print(f"✅ Created {apk_dest}")

        print(f"✅ Created {apk_dest}")

    elif variant == "esim9":
        if build_android:
            print("Building Android 9eSIM...")
            run_cmd([
                "flutter", "build", "apk", "--release", "--split-per-abi", "--flavor", "esim9", 
                "--target-platform", "android-arm64", "--dart-define=ESIM9_BUILD=true", "--dart-define=APP_VARIANT=esim9", "--dart-define=ENABLE_ZXING=false",
                "--obfuscate", "--split-debug-info=release/symbols"
            ])
            apk_src = "build/app/outputs/flutter-apk/app-arm64-v8a-esim9-release.apk"
            apk_dest = f"{release_dir}/ee.nekoko.nlpa.flavor1-{v_filename}-arm64-v8a.apk"
            shutil.copy2(apk_src, apk_dest)
            print(f"✅ Created {apk_dest}")
            
            # Build AAB for 9eSIM variant
            print("Building Android 9eSIM AAB...")
            run_cmd([
                "flutter", "build", "appbundle", "--release", "--flavor", "esim9", 
                "--dart-define=ESIM9_BUILD=true", "--dart-define=APP_VARIANT=esim9", "--dart-define=ENABLE_ZXING=false",
                "--obfuscate", "--split-debug-info=release/symbols"
            ])
            aab_src = "build/app/outputs/bundle/esim9Release/app-esim9-release.aab"
            aab_dest = f"{release_dir}/ee.nekoko.nlpa.flavor1-{v_filename}.aab"
            shutil.copy2(aab_src, aab_dest)
            print(f"✅ Created {aab_dest}")

        if build_linux:
             print("Skipping Linux build for 9eSIM (not supported).")

    elif variant == "store":
        if build_android:
            print("Building Android Store...")
            run_cmd([
                "flutter", "build", "apk", "--release", "--split-per-abi", "--flavor", "store", 
                "--target-platform", "android-arm64", "--dart-define=APP_VARIANT=std", "--dart-define=ENABLE_ZXING=false",
                "--no-pub", "--obfuscate", "--split-debug-info=release/symbols"
            ])
            apk_src = "build/app/outputs/flutter-apk/app-arm64-v8a-store-release.apk"
            apk_dest = f"{release_dir}/ee.nekoko.nlpa-{v_filename}-arm64-v8a.apk"
            shutil.copy2(apk_src, apk_dest)
            print(f"✅ Created {apk_dest}")
            
            print("Building Android Store AAB...")
            run_cmd([
                "flutter", "build", "appbundle", "--release", "--flavor", "store", 
                "--dart-define=APP_VARIANT=std", "--dart-define=ENABLE_ZXING=false",
                "--no-pub", "--obfuscate", "--split-debug-info=release/symbols"
            ])
            aab_src = "build/app/outputs/bundle/storeRelease/app-store-release.aab"
            aab_dest = f"{release_dir}/ee.nekoko.nlpa-{v_filename}.aab"
            shutil.copy2(aab_src, aab_dest)
            print(f"✅ Created {aab_dest}")

    elif variant == "privileged":
        print("Building Privileged...")
        run_cmd([
            "flutter", "build", "apk", "--release", "--split-per-abi", "--flavor", "privileged", 
            "--target-platform", "android-arm64", "--dart-define=PRIVILEGED_BUILD=true", "--dart-define=ENABLE_ZXING=false",
            "--obfuscate", "--split-debug-info=release/symbols"
        ])
        apk_src = "build/app/outputs/flutter-apk/app-arm64-v8a-privileged-release.apk"
        
        apk_dest = f"{release_dir}/ee.nekoko.nlpa2.privileged-{v_filename}-arm64-v8a.apk"
        shutil.copy2(apk_src, apk_dest)
        magisk_dest = f"{release_dir}/ee.nekoko.nlpa2-{v_filename}.magisk.zip"
        run_cmd([
            "python3", "scripts/package_rooted_android.py", "--apk", apk_src,
            "--output", magisk_dest, "--version", version_str,
        ])
        print(f"Created {apk_dest} and {magisk_dest}")




    else:
        print(f"Unknown variant: {variant}")
        sys.exit(1)


def rebrand_apk(src_apk, dest_apk, config):
    print(f"Creating flavor: {config['suffix']} -> {dest_apk}")
    shutil.copy2(src_apk, dest_apk)
    
    # Swap Flutter logo asset
    logo_src = config.get('logo_file')
    if logo_src:
        repo_root = os.path.abspath(os.path.join(os.getcwd(), "..")) # We are in NekokoLPA2, repo root is up 1
        # But wait, config 'logo_file' is "NekokoLPA2/assets/logo_multi.png" which assumes repo root.
        # If we are in NekokoLPA2, we should adjust.
        # Let's try to locate it.
        # 'logo_src' from config is relative to monorepo root (Kasutera).
        # user structure: Kasutera/NekokoLPA2
        full_logo_src = os.path.abspath(os.path.join("..", logo_src))
        
        if os.path.exists(full_logo_src):
            print(f"  Swapping Flutter logo asset: {logo_src}")
            flutter_asset_path = "assets/flutter_assets/assets/logo.png"
            logo_temp = f"temp_logo_{config['suffix']}"
            if os.path.exists(logo_temp): shutil.rmtree(logo_temp)
            
            target_file = f"{logo_temp}/{flutter_asset_path}"
            os.makedirs(os.path.dirname(target_file), exist_ok=True)
            shutil.copy2(full_logo_src, target_file)
            
            run_cmd(["zip", "-r", "-u", os.path.abspath(dest_apk), "assets"], cwd=logo_temp)
            shutil.rmtree(logo_temp)
        else:
            print(f"  ⚠️  Logo source not found: {full_logo_src}")

    # Swap flavor.json
    suffix = config['suffix']
    print(f"  Swapping flavor.json -> {suffix}")
    flavor_asset_path = "assets/flutter_assets/assets/flavor.json"
    flavor_temp = f"temp_flavor_{suffix}"
    if os.path.exists(flavor_temp): shutil.rmtree(flavor_temp)
    
    target_file = f"{flavor_temp}/{flavor_asset_path}"
    os.makedirs(os.path.dirname(target_file), exist_ok=True)
    with open(target_file, "w") as f:
        f.write('{"flavor": "' + suffix + '"}')
    
    run_cmd(["zip", "-r", "-u", os.path.abspath(dest_apk), "assets"], cwd=flavor_temp)
    shutil.rmtree(flavor_temp)

    # Zipalign
    zipalign = find_zipalign()
    if zipalign:
        print(f"Aligning {dest_apk}...")
        unaligned_apk = dest_apk + ".unaligned"
        shutil.move(dest_apk, unaligned_apk)
        try:
            # -f: force overwrite (not needed if we moved)
            # -p: page align shared libs (4KB)
            # -v: verbose
            # 4: alignment (4 bytes)
            run_cmd([zipalign, "-f", "-p", "4", unaligned_apk, dest_apk])
            os.remove(unaligned_apk)
        except Exception as e:
            print(f"Error during zipalign: {e}")
            # Restore if failed?
            if os.path.exists(unaligned_apk):
                shutil.move(unaligned_apk, dest_apk)
            sys.exit(1)
    else:
        print("⚠️ Warning: zipalign not found. APK might be unaligned and fail to install.")

    # The experimental package uses a public rotation proof plus just its leaf.
    if config.get("lineage"):
        from android_lineage import Signer, sign_apk
        repo_root = os.path.abspath(os.path.join(SCRIPT_DIR, "../.."))
        leaf = config["key_configs"][-1]
        sign_apk(
            dest_apk, dest_apk,
            os.environ.get("NLPA_SIGNING_LINEAGE", os.path.join(repo_root, "signing/multi.lineage")),
            Signer(
                Path(os.environ.get("NLPA_LINEAGE_KEYSTORE", os.path.join(repo_root, leaf["ks"]))),
                os.environ.get("NLPA_LINEAGE_STORE_PASSWORD") or signing_password(leaf["ks"]),
                os.environ.get("NLPA_LINEAGE_KEY_ALIAS"),
                os.environ.get("NLPA_LINEAGE_KEY_PASSWORD"),
            ),
            Path(APKSIGNER),
        )
        return

    # Sign
    sign_cmd = ["java", "-jar", APKSIGNER, "sign", 
                "--v1-signing-enabled", "true", 
                "--v2-signing-enabled", "true", 
                "--v3-signing-enabled", "false"]
    
    signer_dir = os.path.dirname(APKSIGNER)
    for kc in config['key_configs']:
        # If ks path starts with "signer/", resolve it relative to repo root or signer dir
        # Our config has "signer/xxx.jks".
        # Let's resolve it relative to SCRIPT_DIR/../../
        repo_root = os.path.abspath(os.path.join(SCRIPT_DIR, "../.."))
        ks_path = os.path.join(repo_root, kc['ks'])
        
        sign_cmd.extend(["--ks", ks_path, "--ks-pass", "env:" + password_environment(kc["ks"]), "--next-signer"])
    
    if sign_cmd[-1] == "--next-signer":
        sign_cmd.pop()
        
    sign_cmd.append(dest_apk)
    run_cmd(sign_cmd)
    
    # Verify
    print(f"Verifying {dest_apk}...")
    run_cmd(["java", "-jar", APKSIGNER, "verify", "--print-certs", dest_apk])


def package_linux(bundle_dir, release_dir, base_name, variant, app_name="NekokoLPA"):
    # Determine config if any
    flavor_conf = next((f for f in CONFIG if f["suffix"] == variant), None)
    
    # 1. Rebrand if needed (logo and flavor.json)
    asset_dir = os.path.join(bundle_dir, "data/flutter_assets/assets")
    if flavor_conf:
        logo_src = flavor_conf.get('logo_file')
        if logo_src:
            full_logo_src = os.path.abspath(os.path.join("..", logo_src))
            if os.path.exists(full_logo_src):
                print(f"  Swapping Linux logo asset: {logo_src}")
                shutil.copy2(full_logo_src, os.path.join(asset_dir, "logo.png"))
        
        print(f"  Swapping Linux flavor.json -> {variant}")
        with open(os.path.join(asset_dir, "flavor.json"), "w") as f:
            f.write('{"flavor": "' + variant + '"}')
    elif variant == "esim9":
         print(f"  Setting flavor.json -> esim9")
         with open(os.path.join(asset_dir, "flavor.json"), "w") as f:
            f.write('{"flavor": "esim9"}')
    
    # 2. Create tar.gz
    tar_dest = f"{release_dir}/{base_name}-x64.tar.gz"
    run_cmd(["tar", "-czf", os.path.abspath(tar_dest), "."], cwd=bundle_dir)
    print(f"✅ Created {tar_dest}")
    
    # 3. Create AppImage
    create_appimage(bundle_dir, release_dir, base_name, app_name)

def create_appimage(bundle_dir, release_dir, base_name, app_name):
    print(f"Creating AppImage for {base_name} ({app_name})...")
    # AppDir structure
    app_dir = "build/linux/AppDir"
    if os.path.exists(app_dir): shutil.rmtree(app_dir)
    os.makedirs(app_dir)
    
    # Copy bundle contents to AppDir root
    for item in os.listdir(bundle_dir):
        s = os.path.join(bundle_dir, item)
        d = os.path.join(app_dir, item)
        if os.path.isdir(s):
            shutil.copytree(s, d)
        else:
            shutil.copy2(s, d)
            
    # Create .desktop file
    desktop_content = f"""[Desktop Entry]
Name={app_name}
Exec=nlpa2
Icon=ee.nekoko.nlpa2
Type=Application
Categories=Utility;
Terminal=false
"""
    with open(os.path.join(app_dir, "ee.nekoko.nlpa2.desktop"), "w") as f:
        f.write(desktop_content)
        
    # Copy Icon to root of AppDir
    icon_src = os.path.join(bundle_dir, "data/flutter_assets/assets/logo.png")
    if os.path.exists(icon_src):
        shutil.copy2(icon_src, os.path.join(app_dir, "ee.nekoko.nlpa2.png"))
    else:
        # Fallback to a generic icon if logo.png is missing
        print("  ⚠️  Warning: logo.png not found for AppImage icon")
        
    # Create AppRun wrapper
    apprun_content = """#!/bin/sh
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export LD_LIBRARY_PATH="$HERE/lib:$LD_LIBRARY_PATH"
exec "$HERE/nlpa2" "$@"
"""
    with open(os.path.join(app_dir, "AppRun"), "w") as f:
        f.write(apprun_content)
    os.chmod(os.path.join(app_dir, "AppRun"), 0o755)
    
    # Build AppImage using appimagetool
    appimage_dest = os.path.abspath(f"{release_dir}/{base_name}-x64.AppImage")
    
    # We need to set ARCH for appimagetool
    env = os.environ.copy()
    env["ARCH"] = "x86_64"
    
    try:
        # Try to call appimagetool. We use --appimage-extract-and-run because we might be in a container without FUSE
        subprocess.run(["appimagetool", "--appimage-extract-and-run", os.path.abspath(app_dir), appimage_dest], check=True, env=env)
        print(f"✅ Created {appimage_dest}")
    except Exception as e:
        print(f"⚠️  Failed to create AppImage: {e}")
        print("  (Ensure 'appimagetool' is in PATH and executable)")


if __name__ == "__main__":
    main()
