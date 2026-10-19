@echo off
REM Secure Android App Bundle (.aab) Build Script for Google Play Store
REM - Obfuscates Dart code
REM - Splits debug symbols
REM - Builds signed release AAB

echo ===================================================
echo Starting Secure Android App Bundle (.aab) Build...
echo ===================================================

if not exist "pubspec.yaml" (
    echo [ERROR] pubspec.yaml not found. Please run this script from the Flutter project root.
    pause
    exit /b 1
)

echo [1/2] Creating symbols output directory...
if not exist "build\app\outputs\symbols" mkdir "build\app\outputs\symbols"

echo [2/2] Running flutter build appbundle with obfuscation...
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

if %ERRORLEVEL% equ 0 (
    echo.
    echo ===================================================
    echo BUILD SUCCESSFUL!
    echo Bundle location: build\app\outputs\bundle\release\app-release.aab
    echo Symbol files:    build\app\outputs\symbols
    echo ===================================================
) else (
    echo.
    echo [ERROR] Build failed with exit code %ERRORLEVEL%.
)
