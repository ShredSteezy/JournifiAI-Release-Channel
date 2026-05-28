@echo off
REM ================================================================
REM   Journifi AI + NinjaTrader Launcher
REM
REM   Original NT launcher by AlphaWolfTrader (Chris).
REM   Two-app launch suggested by Xdzatx — thanks for the nudge that
REM   turned a single-app script into a one-click trading setup.
REM
REM   What this does:
REM     1. Launches NinjaTrader 8 with HIGH process priority and
REM        Server GC enabled (faster bar processing, less GC pause)
REM     2. Launches Journifi AI in parallel
REM
REM   If either app fails to launch, you'll see a [WARNING] line
REM   telling you where it expected to find the .exe. Edit the
REM   paths in the CONFIG section below if your installs live
REM   somewhere else.
REM ================================================================

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
if exist "%JOURNIFI_EXE_MACHINE%" (
    start "" "%JOURNIFI_EXE_MACHINE%"
    echo [OK] Journifi AI launched ^(per-machine install^)
) else if exist "%JOURNIFI_EXE_USER%" (
    start "" "%JOURNIFI_EXE_USER%"
    echo [OK] Journifi AI launched ^(per-user install^)
) else (
    echo [WARNING] Journifi AI not found at either expected location:
    echo             - %JOURNIFI_EXE_MACHINE%
    echo             - %JOURNIFI_EXE_USER%
    echo           Edit JOURNIFI_EXE_* in the CONFIG section if your install is elsewhere.
)
echo.

echo ================================================================
echo Launcher complete. Both apps should be coming up now.
echo ================================================================
echo.
echo Press any key to close this window...
pause >nul
