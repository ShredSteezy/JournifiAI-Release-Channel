@echo off
REM Run this AFTER a NinjaTrader update or reinstall, with NinjaTrader closed.
REM   1) puts the junction back (moves the data folder out of Documents again,
REM      keeping anything the installer added),
REM   2) merges the GC performance paragraph into the new NinjaTrader.exe.config
REM      (the installer ships a fresh config without it; the old file is never
REM      copied over the new one because its assembly redirects would be stale).
REM JournifiAI-NT-Launcher.bat does both of these on every launch, so this file
REM is only for doing it by hand. Needs administrator rights for step 2.
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges for the config merge...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
call "%~dp0NinjaTrader8_EnsureLink.bat" /quiet
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0NinjaTrader8_EnsureGcConfig.ps1" -Quiet
echo.
pause
