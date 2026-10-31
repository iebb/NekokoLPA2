# Windows Build and Installer Instructions

This directory contains scripts to build and create an installer for the Windows version of nlpa2.

## Prerequisites

1. **Flutter SDK** - Already installed
2. **Inno Setup** - Download and install from: https://jrsoftware.org/isdl.php
   - Default installation path: `C:\Program Files (x86)\Inno Setup 6\`
   - If installed elsewhere, update the path in the build scripts

## Updating the App Icon

The app icon is located at `windows/runner/resources/app_icon.ico`.

To update it from `assets/logo.png`:

### Option 1: Using PowerShell Script (if ImageMagick is installed)
```powershell
cd nlpa2
.\scripts\update_icon.ps1
```

### Option 2: Using ImageMagick directly
```powershell
magick convert assets\logo.png -define icon:auto-resize=256,128,64,48,32,16 windows\runner\resources\app_icon.ico
```

### Option 3: Online Converter
1. Go to https://convertio.co/png-ico/ or https://www.icoconverter.com/
2. Upload `assets/logo.png`
3. Download the `.ico` file
4. Save it as `windows/runner/resources/app_icon.ico`

### Option 4: Using Visual Studio
1. Open Visual Studio
2. Create a new Resource File or open an existing `.ico` file
3. Import your logo and export with multiple sizes (16x16, 32x32, 48x48, 64x64, 128x128, 256x256)
4. Save as `windows/runner/resources/app_icon.ico`

## Building the Installer

### Using PowerShell (Recommended)
```powershell
cd nlpa2
.\scripts\build_windows_installer.ps1
```

If Inno Setup is installed in a non-default location:
```powershell
.\scripts\build_windows_installer.ps1 -InnoSetupPath "C:\Your\Path\To\ISCC.exe"
```

### Using Batch File
```cmd
cd nlpa2
scripts\build_windows_installer.bat
```

### Manual Steps

1. **Build Flutter Windows Release:**
   ```powershell
   flutter build windows --release
   ```

2. **Compile Inno Setup Script:**
   - Open Inno Setup Compiler
   - Open `scripts/installer.iss`
   - Click "Build" → "Compile"
   - Or use command line:
     ```cmd
     "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" scripts\installer.iss
     ```

3. **Find the Installer:**
   - The installer will be created in `build\windows\installer\`
   - Filename format: `nlpa2-{version}-setup.exe`

## Installer Features

The installer includes:
- ✅ Automatic version detection from `pubspec.yaml`
- ✅ Desktop shortcut (optional)
- ✅ Start menu entry
- ✅ Uninstaller
- ✅ Admin privileges for installation
- ✅ 64-bit architecture support

## Customizing the Installer

Edit `scripts/installer.iss` to customize:
- App name, publisher, URLs
- Installation directory
- Additional files to include
- Custom installation steps
- License file
- Welcome/finish pages

## Publishing to GitHub Releases

The `publish_windows_github.ps1` script (in the root directory) builds the Windows app, creates an installer, and publishes it to GitHub Releases.

### Prerequisites

1. **GitHub CLI** - Install from: https://cli.github.com/
2. **GitHub Authentication** - Run `gh auth login` to authenticate
3. **Inno Setup** - Required for creating the installer (see above)

### Usage

```powershell
# From the root directory
.\publish_windows_github.ps1
```

### Options

- `-InnoSetupPath`: Custom path to Inno Setup compiler (default: `C:\Program Files (x86)\Inno Setup 6\ISCC.exe`)
- `-GitHubRepo`: GitHub repository (default: `iebb/NekokoLPA2`)
- `-SkipBuild`: Skip Flutter build step (use existing build)
- `-SkipInstaller`: Skip installer creation (use existing installer)

### Examples

```powershell
# From root directory - Full build and publish
.\publish_windows_github.ps1

# Skip build, only create installer and publish
.\publish_windows_github.ps1 -SkipBuild

# Custom Inno Setup path
.\publish_windows_github.ps1 -InnoSetupPath "D:\Tools\Inno Setup 6\ISCC.exe"
```

### How It Works

1. **Reads version** from `pubspec.yaml` (e.g., `2.0.0+27`)
2. **Builds Flutter Windows release** (unless `-SkipBuild` is used)
3. **Creates installer** using Inno Setup (unless `-SkipInstaller` is used)
4. **Checks if release exists**:
   - If release exists: Uploads installer as a new asset (removes old installer if present)
   - If release doesn't exist: Creates new release with installer and release notes from `CHANGELOG.md`

### Release Tag Format

The script uses the version from `pubspec.yaml` to create the release tag:
- Version: `2.0.0+27` → Tag: `v2.0.0+27`

## Troubleshooting

### "Inno Setup not found"
- Install Inno Setup from https://jrsoftware.org/isdl.php
- Or update the path in the build script

### "Flutter build failed"
- Ensure Flutter is properly set up: `flutter doctor`
- Check that all dependencies are installed: `flutter pub get`

### "GitHub CLI not found" or "GitHub CLI not authenticated"
- Install GitHub CLI from https://cli.github.com/
- Authenticate: `gh auth login`
- Verify: `gh auth status`

### "Failed to upload asset to GitHub release"
- Check your GitHub authentication: `gh auth status`
- Verify you have write access to the repository
- Check if the release tag exists: `gh release view v2.0.0+27 --repo iebb/NekokoLPA2`

### Icon not updating
- Ensure the `.ico` file has multiple sizes (16, 32, 48, 64, 128, 256)
- Rebuild the Flutter app after updating the icon
- Clear build cache: `flutter clean`
