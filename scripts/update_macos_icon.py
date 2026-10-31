import os
import shutil
import subprocess

def update_macos_icon():
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    icns_path = os.path.join(project_root, "../icons/icon-blue/macos/AppIcon.icns")
    temp_iconset_dir = os.path.join(project_root, "build/temp_AppIcon.iconset")
    dest_dir = os.path.join(project_root, "macos/Runner/Assets.xcassets/AppIcon.appiconset")

    if not os.path.exists(icns_path):
        print(f"Error: Source icns file not found at {icns_path}")
        exit(1)

    # Clean previous temp
    if os.path.exists(temp_iconset_dir):
        shutil.rmtree(temp_iconset_dir)

    print(f"Converting {icns_path}...")
    try:
        subprocess.check_call(["iconutil", "-c", "iconset", icns_path, "-o", temp_iconset_dir])
    except subprocess.CalledProcessError as e:
        print(f"Error running iconutil: {e}")
        exit(1)

    # Map iconutil output names to AppIcon.appiconset names
    # iconutil format: icon_{WxH}[@2x].png
    # Destination format: see Contents.json
    
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

    print(f"Updating icons in {dest_dir}...")
    for src_name, dest_name in mapping.items():
        src_file = os.path.join(temp_iconset_dir, src_name)
        dest_file = os.path.join(dest_dir, dest_name)
        
        if os.path.exists(src_file):
            shutil.copy2(src_file, dest_file)
            print(f"  Updated {dest_name}")
        else:
            print(f"  Warning: {src_name} not found in generated iconset")

    # Clean up
    if os.path.exists(temp_iconset_dir):
        shutil.rmtree(temp_iconset_dir)
        
    print("MacOS icon update complete.")

if __name__ == "__main__":
    update_macos_icon()
