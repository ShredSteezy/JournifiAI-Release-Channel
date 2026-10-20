@echo off
setlocal EnableExtensions
title NinjaTrader 8 - Check the data-folder link
REM ---------------------------------------------------------------------------
REM  Read-only. Shows how NinjaTrader's Documents folder is wired right now.
REM  Changes nothing. Safe to run any time, with NinjaTrader open or closed.
REM
REM  Optional argument: the data folder (default C:\NinjaTrader8Data)
REM ---------------------------------------------------------------------------
set "DATA=C:\NinjaTrader8Data"
if not "%~1"=="" set "DATA=%~1"

REM The SAME call NinjaTrader uses to find "Documents" (OneDrive-redirected or not)
for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('MyDocuments')"`) do set "DOCS=%%D"
REM Test hook only: NT8_LINK_PARENT points the check at a sandbox folder.
if defined NT8_LINK_PARENT set "DOCS=%NT8_LINK_PARENT%"
set "LINK=%DOCS%\NinjaTrader 8"

for /f "usebackq tokens=1,* delims=|" %%A in (`powershell -NoProfile -Command "$i = Get-Item -LiteralPath '%LINK%' -Force -ErrorAction SilentlyContinue; if ($i) { $t = if ($i.LinkType) { $i.LinkType } else { 'Directory' }; $t + '|' + ($i.Target -join ',') } else { 'Missing|' }"`) do (set "LTYPE=%%A" & set "TARGET=%%B")

set "NTRUN=no"
tasklist /FI "IMAGENAME eq NinjaTrader.exe" 2>nul | find /I "NinjaTrader.exe" >nul && set "NTRUN=YES"

echo ===============================================================
echo  NinjaTrader 8 data-folder link
echo ===============================================================
echo  Documents folder  : %DOCS%
echo  NinjaTrader looks : %LINK%
echo  That path is      : %LTYPE%
if /I "%LTYPE%"=="Junction" echo  ...pointing at    : %TARGET%
echo  Data folder       : %DATA%
if exist "%DATA%\bin\Custom\" (echo  Data folder holds : NinjaTrader data ^(bin\Custom found^)) else (echo  Data folder holds : NOT a NinjaTrader data folder ^(no bin\Custom^))
echo  NinjaTrader open  : %NTRUN%
echo ---------------------------------------------------------------
if /I "%LTYPE%"=="Junction" (
  if /I "%TARGET%"=="%DATA%" (
    echo  STATE: LINKED. NinjaTrader reads and writes %DATA% through the junction.
  ) else (
    echo  STATE: LINKED, but to a different folder than expected.
    echo         Pass that folder as the argument to NinjaTrader8_EnsureLink.bat
  )
) else if /I "%LTYPE%"=="Directory" (
  echo  STATE: UNLINKED. "%LINK%" is a real folder.
  echo         Close NinjaTrader and run NinjaTrader8_EnsureLink.bat - it keeps
  echo         everything and puts the junction back.
) else (
  echo  STATE: no NinjaTrader 8 folder in Documents at all.
  echo         Run NinjaTrader8_EnsureLink.bat to create the junction.
)
echo ===============================================================
pause
exit /b 0
