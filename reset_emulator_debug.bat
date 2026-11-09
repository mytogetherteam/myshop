@echo off
echo ========================================================
echo   Resetting Android Emulator ADB & Logcat Buffer
echo ========================================================

set ADB="%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
if not exist %ADB% (
    set ADB=adb
)

echo [1/4] Restarting ADB server...
%ADB% kill-server >nul 2>&1
%ADB% start-server >nul 2>&1

echo [2/4] Removing stale ADB forwards...
%ADB% forward --remove-all >nul 2>&1

echo [3/4] Expanding emulator logcat ring buffer to 16MB...
%ADB% logcat -G 16M >nul 2>&1
%ADB% logcat -c >nul 2>&1

echo [4/4] Force-stopping app background processes...
%ADB% shell am force-stop com.mytogether.myshop >nul 2>&1

echo.
echo ========================================================
echo   Done! Your emulator is now ready for Flutter debugging.
echo ========================================================
pause
