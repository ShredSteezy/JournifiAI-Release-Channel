@echo off
REM Run this BEFORE a NinjaTrader update or reinstall, with NinjaTrader closed.
REM The Windows Installer cannot work through the junction (error 2330), so this
REM turns Documents\NinjaTrader 8 back into a plain folder for the installer.
REM Nothing is copied or deleted: the data folder is renamed into place.
REM Afterwards: run the installer, then NinjaTrader8_2_AfterUpdate.bat (or just
REM launch through JournifiAI-NT-Launcher.bat, which does the same thing).
REM Needs administrator rights: the data folder sits at the root of C:, and only
REM an elevated process may rename it. Click Yes on the prompt.
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
call "%~dp0NinjaTrader8_EnsureLink.bat" /unlink
