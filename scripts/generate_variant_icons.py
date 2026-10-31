import os
import sys
import shutil

# Definitions
VARIANTS = {
    'normal': {
        'source_dir': '../icons/icon-blue/android/res',
        'res_dir': 'android/app/src/normal/res',
        'is_android_res': True
    },
    'privileged': {
        'source_dir': '../icons/icon-pink/android/res',
        'res_dir': 'android/app/src/privileged/res', 
        'is_android_res': True
    },
    'm': {
        'source_dir': '../icons/icon-teal/android/res',
        'res_dir': 'android/app/src/m/res',
        'is_android_res': True
    },
    'ios': {
        'source_dir': '../icons/icon-blue/ios',
        'res_dir': 'ios/Runner/Assets.xcassets/AppIcon.appiconset',
        'is_ios': True
    }
}

def copy_icons():
    print("Copying icons...")
    
    for variant, config in VARIANTS.items():
        if config.get('is_android_res'):
            src_base_dir = config['source_dir']
            dest_base_dir = config['res_dir']
            
            if not os.path.exists(src_base_dir):
                print(f"Error: Source directory {src_base_dir} does not exist.")
                sys.exit(1)

            print(f"Processing Android variant: {variant}")
            
            # List of mipmap folders to process
            mipmap_folders = [d for d in os.listdir(src_base_dir) if d.startswith('mipmap-')]
            
            for folder in mipmap_folders:
                src_dir = os.path.join(src_base_dir, folder)
                dest_dir = os.path.join(dest_base_dir, folder)
                
                if not os.path.isdir(src_dir):
                    continue
                
                os.makedirs(dest_dir, exist_ok=True)
                
                # Copy ic_launcher.png, foreground, background
                files_to_copy = ['ic_launcher.png', 'ic_launcher_foreground.png', 'ic_launcher_background.png']
                
                for filename in files_to_copy:
                    src_file = os.path.join(src_dir, filename)
                    if os.path.exists(src_file):
                        shutil.copy2(src_file, os.path.join(dest_dir, filename))
                        print(f"  Copied {folder}/{filename}")
                        
        elif config.get('is_ios'):
            src_dir = config['source_dir']
            dest_dir = config['res_dir']
            
            if not os.path.exists(src_dir):
                print(f"Error: Source directory {src_dir} does not exist.")
                sys.exit(1)

            print(f"Processing iOS variant: {variant}")
            
            if os.path.exists(dest_dir):
                shutil.rmtree(dest_dir)
            
            shutil.copytree(src_dir, dest_dir)
            print(f"  Replaced {dest_dir}")

if __name__ == "__main__":
    copy_icons()
