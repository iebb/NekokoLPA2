# PowerShell script to build Windows installer using Inno Setup
# Requires Inno Setup to be installed: https://jrsoftware.org/isdl.php

param(
    [string]$InnoSetupPath = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
)

$ErrorActionPreference = "Stop"

# Get version from pubspec.yaml
$pubspecPath = Join-Path $PSScriptRoot "..\pubspec.yaml"
$versionLine = Select-String -Path $pubspecPath -Pattern "^version:" | Select-Object -First 1
$version = ($versionLine.Line -replace "version:\s*", "").Trim()
$versionName = ($version -split "\+")[0]
$buildNumber = ($version -split "\+")[1]

Write-Host "Building Windows installer for nlpa2 v$versionName (build $buildNumber)" -ForegroundColor Cyan

# Navigate to nlpa2 directory
$nlpa2Dir = Join-Path $PSScriptRoot ".."
Push-Location $nlpa2Dir

try {
    # Build Flutter Windows release
    Write-Host "`n[1/3] Building Flutter Windows release..." -ForegroundColor Yellow
    flutter build windows --release "--dart-define=GM_PSK_URL=$env:GM_PSK_URL"
    
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter build failed"
    }
    
    # Check if Inno Setup is installed
    if (-not (Test-Path $InnoSetupPath)) {
        Write-Host "`nInno Setup not found at: $InnoSetupPath" -ForegroundColor Red
        Write-Host "Please install Inno Setup from: https://jrsoftware.org/isdl.php" -ForegroundColor Yellow
        Write-Host "Or specify the path using -InnoSetupPath parameter" -ForegroundColor Yellow
        throw "Inno Setup not found"
    }
    
    # Create installer using Inno Setup
    Write-Host "`n[2/3] Creating installer with Inno Setup..." -ForegroundColor Yellow
    $issFile = Join-Path $nlpa2Dir "scripts\installer.iss"
    
    if (-not (Test-Path $issFile)) {
        throw "Installer script not found: $issFile"
    }
    
    & $InnoSetupPath $issFile
    
    if ($LASTEXITCODE -ne 0) {
        throw "Inno Setup compilation failed"
    }
    
    # Find the output installer
    $outputDir = Join-Path $nlpa2Dir "build\windows\installer"
    $installerName = "ee.nekoko.nlpa2.windows-${versionName}-${buildNumber}-setup.exe"
    $installerPath = Join-Path $outputDir $installerName
    
    if (Test-Path $installerPath) {
        Write-Host "`n[3/3] Installer created successfully!" -ForegroundColor Green
        Write-Host "Location: $installerPath" -ForegroundColor Cyan
        Write-Host "Size: $([math]::Round((Get-Item $installerPath).Length / 1MB, 2)) MB" -ForegroundColor Cyan
    } else {
        # Try default Inno Setup output location
        $defaultOutput = Join-Path $env:USERPROFILE "Documents\Inno Setup Scripts\Output\$installerName"
        if (Test-Path $defaultOutput) {
            Write-Host "`n[3/3] Installer created successfully!" -ForegroundColor Green
            Write-Host "Location: $defaultOutput" -ForegroundColor Cyan
            Write-Host "Size: $([math]::Round((Get-Item $defaultOutput).Length / 1MB, 2)) MB" -ForegroundColor Cyan
        } else {
            throw "Installer not found in expected locations"
        }
    }
    
} finally {
    Pop-Location
}
