# Quick Icon Update Guide

## Windows Icon (.ico)

### Option 1: Online Converter (Easiest)
1. Go to https://convertio.co/png-ico/
2. Upload `assets/logo.png`
3. Click "Convert"
4. Download the `.ico` file
5. Save it as `windows/runner/resources/app_icon.ico`
6. **Important**: Make sure the converter creates a multi-size ICO (16, 32, 48, 64, 128, 256px)

### Option 2: Using Python (if installed)
```powershell
pip install Pillow
python scripts/update_all_icons.py
```

### Option 3: Using ImageMagick (if installed)
```powershell
magick convert assets\logo.png -define icon:auto-resize=256,128,64,48,32,16 windows\runner\resources\app_icon.ico
```

## Android Icons

Android needs icons in multiple sizes. You can:

1. **Use the Python script** (if Python is installed):
   ```powershell
   pip install Pillow
   python scripts/update_all_icons.py
   ```

2. **Manual method**:
   - Use https://www.iloveimg.com/resize-image to resize `assets/logo.png` to:
     - 48x48 → `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
     - 72x72 → `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
     - 96x96 → `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
     - 144x144 → `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
     - 192x192 → `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`

## After Updating Icons

1. **Windows**: Rebuild the app
   ```powershell
   flutter clean
   flutter build windows
   ```

2. **Android**: Rebuild the app
   ```powershell
   flutter clean
   flutter build apk
   ```

## Current Icon Locations

- **Windows**: `windows/runner/resources/app_icon.ico`
- **Android**: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- **Source Logo**: `assets/logo.png`
