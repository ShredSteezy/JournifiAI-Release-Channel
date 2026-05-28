@echo off
REM ================================================================
REM   Journifi AI + NinjaTrader Launcher
REM
REM   Original NT launcher by AlphaWolfTrader (Chris).
REM   Two-app launch suggested by Xdzatx -- thanks for the nudge that
REM   turned a single-app script into a one-click trading setup.
REM
REM   What this does:
REM     1. Launches NinjaTrader 8 with HIGH process priority and
REM        Server GC enabled (faster bar processing, less GC pause)
REM     2. Launches Journifi AI in parallel
REM
REM   You'll see a UAC prompt the first time you run this -- that's
REM   normal. /HIGH priority on the NT process requires admin rights
REM   (a Windows security setting; nothing this script is doing is
REM   actually risky -- just launching two installed programs). Click
REM   Yes and both apps will boot.
REM
REM   If either app fails to launch, you'll see a [WARNING] line
REM   telling you where it expected to find the .exe. Edit the
REM   paths in the CONFIG section below if your installs live
REM   somewhere else.
REM ================================================================

REM ── Self-elevate to administrator if not already elevated ──────
REM /HIGH process priority requires SeIncreaseBasePriorityPrivilege,
REM which standard users don't have. Without admin, /HIGH gets
REM silently downgraded to NORMAL and we lose the perf bump. Check
REM via "net session" -- returns success only when running as admin.
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

setlocal enabledelayedexpansion
title Journifi AI + NinjaTrader Launcher
color 0A

REM -- CONFIG: edit these paths if your installs are non-default --
set "NT_EXE=C:\Program Files\NinjaTrader 8\bin\NinjaTrader.exe"
set "NT_CONFIG=C:\Program Files\NinjaTrader 8\bin\NinjaTrader.exe.config"

REM Journifi AI: tries the "All Users" install first, falls back to
REM the per-user install location automatically. Most testers won't
REM need to edit these -- the installer picks one of these two paths.
set "JOURNIFI_EXE_MACHINE=C:\Program Files\Journifi AI\Journifi AI.exe"
set "JOURNIFI_EXE_USER=%LOCALAPPDATA%\Programs\Journifi AI\Journifi AI.exe"

echo ================================================================
echo    Journifi AI + NinjaTrader 8 Launcher
echo    Script: AlphaWolfTrader  ^|  Two-app idea: Xdzatx
echo ================================================================
echo.

REM -- Launch NinjaTrader --
if exist "%NT_EXE%" (
    REM Server GC works on .NET Framework via environment variable
    set COMPlus_gcServer=1
    echo [OK] Server GC enabled via environment

    findstr /C:"gcServer" "%NT_CONFIG%" >nul 2>&1
    if !errorlevel!==0 (
        echo [OK] gcServer found in NinjaTrader.exe.config
    ) else (
        echo [WARNING] gcServer NOT found in config
        echo           GC tuning recommended for best performance
    )

    findstr /C:"gcConcurrent" "%NT_CONFIG%" >nul 2>&1
    if !errorlevel!==0 (
        echo [OK] gcConcurrent found in config
    ) else (
        echo [WARNING] gcConcurrent NOT found in config
    )

    echo.
    echo Launching NinjaTrader 8 with HIGH process priority...
    start "" /HIGH "%NT_EXE%"
    echo [OK] NinjaTrader launched
) else (
    echo [WARNING] NinjaTrader not found
    echo           Expected: %NT_EXE%
    echo           Edit NT_EXE in the CONFIG section if your install is elsewhere.
)
echo.

REM -- Launch Journifi AI --
REM
REM Journifi is launched via PowerShell's Start-Process instead of cmd's
REM "start" because Electron apps can stay attached to the launcher's
REM console group when "start" is used. The symptom: X-ing out the
REM launcher window also closes Journifi (Windows sends CTRL_CLOSE_EVENT
REM to the whole console group, and Chromium obediently shuts down).
REM PowerShell Start-Process detaches the child fully via CreateProcess
REM with the right flags, so closing this window has no effect on
REM Journifi -- as it should be.
if exist "%JOURNIFI_EXE_MACHINE%" (
    powershell -WindowStyle Hidden -Command "Start-Process -FilePath '%JOURNIFI_EXE_MACHINE%'"
    echo [OK] Journifi AI launched ^(per-machine install^)
) else if exist "%JOURNIFI_EXE_USER%" (
    powershell -WindowStyle Hidden -Command "Start-Process -FilePath '%JOURNIFI_EXE_USER%'"
    echo [OK] Journifi AI launched ^(per-user install^)
) else (
    echo [WARNING] Journifi AI not found at either expected location:
    echo             - %JOURNIFI_EXE_MACHINE%
    echo             - %JOURNIFI_EXE_USER%
    echo           Edit JOURNIFI_EXE_* in the CONFIG section if your install is elsewhere.
)
echo.

echo ================================================================
echo Launcher complete. Closing in 5 seconds.
echo Both apps run independently -- this window can be safely
echo X'd out or left to close on its own; neither app cares.
echo ================================================================

REM 5-second hold so the user has time to read any warnings above
REM before the window auto-closes. /nobreak ignores keystrokes so
REM the script doesn't exit early on an accidental keypress. The
REM user can still X out the window if they want -- Journifi is
REM properly detached now (PowerShell Start-Process above), so
REM closing this window has no effect on either launched app.
timeout /t 5 /nobreak >nul
