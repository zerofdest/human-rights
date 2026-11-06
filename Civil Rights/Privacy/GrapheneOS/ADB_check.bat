@echo off
setlocal EnableExtensions

where adb >nul 2>&1
if errorlevel 1 (
    echo ERROR: adb was not found in PATH.
    echo Install official Android SDK Platform-Tools and run this file again.
    pause
    exit /b 1
)

adb get-state >nul 2>&1
if errorlevel 1 (
    echo ERROR: No single authorized Android device is connected.
    echo Connect one phone, enable USB debugging, and approve the USB prompt.
    adb devices
    pause
    exit /b 1
)

for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%I"
if not defined STAMP set "STAMP=unknown"
set "OUT=%~dp0phone_check_%STAMP%.txt"

echo Collecting read-only Android diagnostics...
echo This report may include device identifiers or application details.

(
    echo ===== DEVICE IDENTITY =====
    for %%P in (ro.product.manufacturer ro.product.model ro.product.device ro.build.version.release ro.build.version.sdk ro.build.version.security_patch ro.boot.verifiedbootstate ro.boot.flash.locked ro.oem_unlock_supported) do (
        echo PROPERTY: %%P
        adb shell getprop %%P
    )
    echo.
    echo ===== BATTERY =====
    adb shell dumpsys battery
    echo.
    echo ===== STORAGE =====
    adb shell df -h /data
    echo.
    echo ===== THERMAL STATUS =====
    adb shell dumpsys thermalservice
    echo.
    echo ===== SENSORS (ENUMERATION AND SERVICE STATE) =====
    adb shell dumpsys sensorservice
    echo.
    echo ===== CAMERA SERVICE =====
    adb shell dumpsys media.camera
    echo.
    echo ===== INPUT AND TOUCH SERVICE =====
    adb shell dumpsys input
) > "%OUT%" 2>&1

if errorlevel 1 (
    echo WARNING: A diagnostic command reported an error. Check the report.
)
echo.
echo Report saved to:
echo %OUT%
echo.
echo IMPORTANT: This only inventories system-reported information.
echo It does NOT prove touch, camera, cellular, audio, or USB hardware works.
echo Test those functions manually with OEM diagnostics and a known-good SIM.
echo Do not publicly share this report without reviewing sensitive details.
pause
endlocal
