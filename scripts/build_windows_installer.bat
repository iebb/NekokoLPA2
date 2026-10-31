@echo off
REM Batch script to build Windows installer using Inno Setup
REM Requires Inno Setup to be installed: https://jrsoftware.org/isdl.php

setlocal

set "INNO_SETUP_PATH=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"

echo Building Windows installer for nlpa2...
echo.

cd /d "%~dp0.."

REM Build Flutter Windows release
echo [1/3] Building Flutter Windows release...
call flutter build windows --release
if errorlevel 1 (
    echo Flutter build failed!
    exit /b 1
)

REM Check if Inno Setup is installed
if not exist "%INNO_SETUP_PATH%" (
    echo.
    echo Inno Setup not found at: %INNO_SETUP_PATH%
    echo Please install Inno Setup from: https://jrsoftware.org/isdl.php
    echo Or edit this script to set INNO_SETUP_PATH to your installation
    exit /b 1
)

REM Create installer using Inno Setup
echo.
echo [2/3] Creating installer with Inno Setup...
"%INNO_SETUP_PATH%" scripts\installer.iss
if errorlevel 1 (
    echo Inno Setup compilation failed!
    exit /b 1
)

echo.
echo [3/3] Installer created successfully!
echo Check build\windows\installer\ for the installer file
echo.

endlocal
