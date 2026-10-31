import json
import os
import shutil
import sys
import subprocess
import re

# This script prepares the assets for a specific flavor.
# It swaps assets/logo.png and updates assets/flavor.json.

# A private overlay may provide brand identities without replacing this engine.
def load_flavors():
    manifest = os.environ.get("NLPA_FLAVORS_FILE", os.path.join(os.path.dirname(__file__), "flavors.json"))
    if not os.path.isfile(manifest):
        return {}
    with open(manifest) as stream:
        records = json.load(stream)
    if not isinstance(records, dict):
        raise ValueError("Flavor manifest must be a JSON object")
    return records

FLAVORS = load_flavors()

def update_pbxproj(path, config):
    if not os.path.exists(path):
        return
    print(f"Updating {path} with flavor settings")
    with open(path, "r") as f:
        content = f.read()
    
    # helper to update a key-value pair in pbxproj with quotes
    def set_kv(content, key, value):
        if not value: return content
        # Use [^\n;]+ to ensure we don't match across lines
        # and always quote the value for pbxproj compatibility
        return re.sub(rf'({key}\s*=\s*)[^\n;]+(;)', r'\g<1>' + f'"{value}"' + r'\g<2>', content)

    new_content = content
    new_content = set_kv(new_content, "PRODUCT_BUNDLE_IDENTIFIER", config.get("bundle_id"))
    new_content = set_kv(new_content, "DEVELOPMENT_TEAM", config.get("development_team"))
    new_content = set_kv(new_content, "INFOPLIST_KEY_CFBundleDisplayName", config.get("app_name"))
    new_content = set_kv(new_content, "IPHONEOS_DEPLOYMENT_TARGET", "15.6")

    with open(path, "w") as f:
        f.write(new_content)

def update_info_plist(path, app_name, bundle_id=None):
    if not os.path.exists(path):
        return
    
    with open(path, "r") as f:
        content = f.read()
    
    new_content = content
    if app_name:
        print(f"Updating {path} with app name: {app_name}")
        # Update CFBundleDisplayName
        if "<key>CFBundleDisplayName</key>" in new_content:
            new_content = re.sub(
                r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)',
                r'\g<1>' + app_name + r'\g<2>',
                new_content
            )
        # Update CFBundleName
        if "<key>CFBundleName</key>" in new_content:
            new_content = re.sub(
                r'(<key>CFBundleName</key>\s*<string>)[^<]*(</string>)',
                r'\g<1>' + app_name + r'\g<2>',
                new_content
            )
            
    if bundle_id:
        print(f"Updating {path} with bundle ID: {bundle_id}")
        if "<key>CFBundleIdentifier</key>" in new_content:
             new_content = re.sub(
                r'(<key>CFBundleIdentifier</key>\s*<string>)[^<]*(</string>)',
                r'\g<1>' + bundle_id + r'\g<2>',
                new_content
            )
        if "<key>CFBundleURLName</key>" in new_content:
             new_content = re.sub(
                r'(<key>CFBundleURLName</key>\s*<string>)[^<]*(</string>)',
                r'\g<1>' + bundle_id + r'\g<2>',
                new_content
            )

    with open(path, "w") as f:
        f.write(new_content)

def update_macos_xcconfig(path, app_name, bundle_id):
    if not os.path.exists(path):
        return
    print(f"Updating {path} with {app_name} / {bundle_id}")
    with open(path, "r") as f:
        content = f.read()
    
    # xcconfig generally doesn't use quotes for values
    new_content = re.sub(r'(PRODUCT_NAME = ).*', r'\g<1>' + app_name, content)
    new_content = re.sub(r'(PRODUCT_BUNDLE_IDENTIFIER = ).*', r'\g<1>' + bundle_id, new_content)
    
    with open(path, "w") as f:
        f.write(new_content)

def remove_associated_domains(path):
    if not os.path.exists(path):
        return
    print(f"Removing associated domains from {path}")
    try:
        subprocess.run(["/usr/libexec/PlistBuddy", "-c", "Delete :com.apple.developer.associated-domains", path], check=False)
    except Exception as e:
        print(f"Warning: Failed to remove associated domains from {path}: {e}")

def main():
    if len(sys.argv) < 2 or sys.argv[1] in ("--help", "-h"):
        print("Usage: python3 prepare_flavor.py <flavor>")
        sys.exit(1)

    if not FLAVORS:
        sys.exit("Flavor preparation requires scripts/flavors.json or NLPA_FLAVORS_FILE. Plain public builds use flutter build directly.")

    flavor = sys.argv[1]
    
    # The app root is the parent of this script's folder (NekokoLPA2/), where
    # the overlay puts it; abspath, not realpath, so a --link symlink counts.
    os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

    if flavor not in FLAVORS and flavor != "std":
        print(f"Unknown flavor: {flavor}")
        sys.exit(1)

    config = FLAVORS.get(flavor, FLAVORS["std"])

    # 1. Update flavor.json
    print(f"Setting flavor to: {flavor}")
    with open("assets/flavor.json", "w") as f:
        json.dump({"flavor": flavor}, f)

    # 2. Swap logo.png
    if flavor == "std":
        print("Restoring standard logo...")
        shutil.copy2("assets/logo-std.png", "assets/logo.png")
    else:
        src_logo = config["logo"]
        if os.path.exists(src_logo):
            print(f"Swapping logo: {src_logo} -> assets/logo.png")
            shutil.copy2(src_logo, "assets/logo.png")
        else:
            print(f"Warning: Source logo {src_logo} not found.")

    # 3. Update iOS assets
    if "icon_path" in config:
        icon_dir = config["icon_path"]
        ios_icon_src = os.path.join(icon_dir, "ios")
        if os.path.exists(ios_icon_src):
            print(f"Updating iOS icons from {ios_icon_src}...")
            ios_dest_dir = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
            if os.path.exists(ios_dest_dir):
                shutil.rmtree(ios_dest_dir)
            shutil.copytree(ios_icon_src, ios_dest_dir)
        else:
            print(f"Warning: iOS icons not found at {ios_icon_src}")

    # 4. Update Android icons
    if "icon_path" in config:
        icon_dir = config["icon_path"]
        android_res_src = os.path.join(icon_dir, "android/res")
        if os.path.exists(android_res_src):
            print(f"Updating Android icons from {android_res_src}...")
            android_res_dest = "android/app/src/main/res"
            if os.path.exists(android_res_dest):
                # Copy mipmap folders
                for item in os.listdir(android_res_src):
                    s = os.path.join(android_res_src, item)
                    d = os.path.join(android_res_dest, item)
                    if os.path.isdir(s) and item.startswith("mipmap-"):
                        if os.path.exists(d):
                            shutil.rmtree(d)
                        shutil.copytree(s, d)
        else:
            print(f"Warning: Android icons not found at {android_res_src}")

    # 5. Update MacOS icons
    if "icon_path" in config:
        icon_dir = config["icon_path"]
        icns_path = os.path.join(icon_dir, "macos/AppIcon.icns")
        
        # Check if we are on macOS
        if sys.platform == "darwin":
            if os.path.exists(icns_path):
                print(f"Updating macOS icons from {icns_path}...")
                dest_dir = "macos/Runner/Assets.xcassets/AppIcon.appiconset"
                
                # We need to run iconutil
                temp_iconset = "build/temp_AppIcon.iconset"
                if not os.path.exists("build"):
                    os.makedirs("build")
                if os.path.exists(temp_iconset):
                    shutil.rmtree(temp_iconset)
                
                try:
                    subprocess.run(["iconutil", "-c", "iconset", icns_path, "-o", temp_iconset], check=True)
                    
                    mapping = {
                        "icon_16x16.png": "16-mac.png",
                        "icon_16x16@2x.png": "32-mac 1.png",
                        "icon_32x32.png": "32-mac.png",
                        "icon_32x32@2x.png": "64-mac.png",
                        "icon_128x128.png": "128-mac.png",
                        "icon_128x128@2x.png": "256-mac 1.png",
                        "icon_256x256.png": "256-mac.png",
                        "icon_256x256@2x.png": "512-mac 1.png",
                        "icon_512x512.png": "512-mac.png",
                        "icon_512x512@2x.png": "1024-mac.png"
                    }
                    
                    if not os.path.exists(dest_dir):
                        os.makedirs(dest_dir)

                    for src_name, dest_name in mapping.items():
                        src_file = os.path.join(temp_iconset, src_name)
                        dest_file = os.path.join(dest_dir, dest_name)
                        if os.path.exists(src_file):
                            shutil.copy2(src_file, dest_file)
                    
                    shutil.rmtree(temp_iconset)
                    print("macOS icons updated.")
                except subprocess.CalledProcessError as e:
                    print(f"Error running iconutil: {e}")
                except Exception as e:
                    print(f"Error updating macOS icons: {e}")
            else:
                 print(f"Warning: macOS icns not found at {icns_path}")
        else:
            print("Skipping macOS icon update (not on macOS).")

    # 6. Update Bundle IDs and App Names
    bundle_id = config.get("bundle_id")
    app_name = config.get("app_name")

    update_pbxproj("ios/Runner.xcodeproj/project.pbxproj", config)
    update_pbxproj("macos/Runner.xcodeproj/project.pbxproj", config)
    
    if app_name or bundle_id:
        update_info_plist("ios/Runner/Info.plist", app_name, bundle_id)
        update_info_plist("macos/Runner/Info.plist", app_name, bundle_id)
        
    if app_name and bundle_id:
        update_macos_xcconfig("macos/Runner/Configs/AppInfo.xcconfig", app_name, bundle_id)

    # 7. Specific flavor tweaks
    if flavor == "esim9":
        remove_associated_domains("ios/Runner/Runner.entitlements")
        remove_associated_domains("macos/Runner/Release.entitlements")
        remove_associated_domains("macos/Runner/DebugProfile.entitlements")
        
        # Cleanup leftover esim9 specific assets if they exist
        esim9_extra_iconset = "ios/Runner/Assets.xcassets/AppIcon-esim9.appiconset"
        if os.path.exists(esim9_extra_iconset):
            print(f"Cleaning up {esim9_extra_iconset}...")
            shutil.rmtree(esim9_extra_iconset)

    # 8. Update Web assets
    print("Updating Web assets (Enforcing std)...")
    std_icon_path = FLAVORS["std"]["icon_path"] # ../icons/icon-blue
    web_src_dir = os.path.join(std_icon_path, "web")
    web_dest_root = "web"
    web_dest_icons = "web/icons"
    
    if os.path.exists(web_src_dir) and os.path.exists(web_dest_root):
        root_files = ["favicon.ico", "apple-touch-icon.png"]
        for f in root_files:
            src = os.path.join(web_src_dir, f)
            dest = os.path.join(web_dest_root, f)
            if os.path.exists(src):
                shutil.copy2(src, dest)

        icon_files = ["icon-192.png", "icon-512.png", "icon-192-maskable.png", "icon-512-maskable.png"]
        if not os.path.exists(web_dest_icons):
            os.makedirs(web_dest_icons)
            
        for f in icon_files:
            src = os.path.join(web_src_dir, f)
            dest = os.path.join(web_dest_icons, f)
            if os.path.exists(src):
                if os.path.exists(dest):
                    os.remove(dest)
                shutil.copy2(src, dest)
        
        print("Web assets updated to std.")

    # 9. Update Android splash logo
    android_splash_dest = "android/app/src/main/res/drawable/launch_image.png"
    if os.path.exists("assets/logo.png") and os.path.exists("android/app/src/main/res/drawable"):
        print(f"Updating Android splash logo...")
        shutil.copy2("assets/logo.png", android_splash_dest)

    print("Done. All assets, bundle IDs, and app names prepared.")

if __name__ == "__main__":
    main()
