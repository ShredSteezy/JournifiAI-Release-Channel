@echo off
setlocal EnableExtensions DisableDelayedExpansion
title NinjaTrader 8 - Ensure the data-folder link
REM ---------------------------------------------------------------------------
REM  Self-healing link between NinjaTrader's Documents folder and the real data
REM  folder that lives outside OneDrive. Run it any time - from a launcher, after
REM  an update, or by hand. It acts only when something is wrong and it NEVER
REM  deletes a file: anything it has to move out of the way is kept beside it.
REM
REM   LINKED    Documents\NinjaTrader 8 is a junction to the data folder -> nothing to do.
REM   UNLINKED  An installer (or a first launch after one) replaced the junction with
REM             a real folder, and the data folder still exists ->
REM               1) copy into the data folder any file the new folder has that the
REM                  data folder lacks (installer defaults; never overwrites yours),
REM               2) move the new folder aside as "NinjaTrader 8.replaced-<stamp>",
REM               3) re-create the junction.
REM   MISSING   No Documents\NinjaTrader 8 at all -> create the junction.
REM   FIRST USE A real folder and NO data folder yet -> move the folder to the data
REM             folder (same drive: an instant rename) and create the junction.
REM
REM  Argument (optional): the data folder.   Default: C:\NinjaTrader8Data
REM  Switch   (optional): /quiet             no pause at the end (for launchers)
REM  Switch   (optional): /unlink            BEFORE running a NinjaTrader installer:
REM             the Windows Installer cannot read file attributes through a junction
REM             (error 2330 on bin\Custom\DrawingTools, measured 2026-10-20 on 8.1.8.4)
REM             and rolls back - taking the previous program files with it. /unlink
REM             removes the junction and renames the data folder INTO Documents, so
REM             the installer meets a plain folder. Afterwards run this script again
REM             (or launch through the launcher): the FIRST USE branch moves the
REM             folder back out and re-creates the junction.
REM ---------------------------------------------------------------------------
set "DATA=C:\NinjaTrader8Data"
set "QUIET="
set "UNLINK="
for %%A in (%*) do (
  if /I "%%~A"=="/quiet" (set "QUIET=1") else if /I "%%~A"=="/unlink" (set "UNLINK=1") else (set "DATA=%%~A")
)

REM The SAME call NinjaTrader uses to find "Documents" (OneDrive-redirected or not)
for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('MyDocuments')"`) do set "DOCS=%%D"
REM Test hook only: NT8_LINK_PARENT points the script at a sandbox folder instead
REM of Documents, so every branch can be proven without touching the real link.
if defined NT8_LINK_PARENT set "DOCS=%NT8_LINK_PARENT%"
set "LINK=%DOCS%\NinjaTrader 8"
for /f "usebackq delims=" %%S in (`powershell -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss"`) do set "STAMP=%%S"

call :detect
echo  Documents : %DOCS%
echo  Link      : %LINK%  [%LTYPE%]
if /I "%LTYPE%"=="Junction" echo  Target    : %TARGET%
echo  Data      : %DATA%
echo.

if /I "%LTYPE%"=="Junction" (
  if /I "%TARGET%"=="%DATA%" (
    if defined UNLINK goto :unlink
    echo  STATE: LINKED - nothing to do.
    goto :ok
  )
  echo  STATE: LINKED, but to "%TARGET%". Not touching it. If that is the right
  echo         data folder, pass it as the argument.
  goto :fail
)
if defined UNLINK (
  echo  STATE: not linked - nothing to unlink. Run the installer, then run this
  echo         script again ^(or the launcher^) to put the junction back.
  goto :ok
)

REM Everything below changes the link, so NinjaTrader must be closed. Never killed:
REM an open position or an unsaved workspace is the trader's to close.
tasklist /FI "IMAGENAME eq NinjaTrader.exe" 2>nul | find /I "NinjaTrader.exe" >nul && (
  echo  STOP: NinjaTrader is running. Close it ^(File ^> Exit^) and run this again.
  goto :fail
)

if /I "%LTYPE%"=="Missing" (
  if not exist "%DATA%\bin\Custom\" (
    echo  STOP: there is no link and "%DATA%" is not a NinjaTrader data folder
    echo        ^(no bin\Custom^). Nothing to link.
    goto :fail
  )
  echo  STATE: MISSING - creating the junction.
  goto :link
)

REM From here LTYPE is Directory: a real folder sits where the junction should be.
if not exist "%DATA%\" goto :firstuse

if not exist "%DATA%\bin\Custom\" (
  echo  STOP: "%DATA%" exists but is not a NinjaTrader data folder ^(no bin\Custom^).
  goto :fail
)
set "ASIDE=%DOCS%\NinjaTrader 8.replaced-%STAMP%"
echo  STATE: UNLINKED - a real folder sits beside your data folder.
echo    1^) copying files it has that "%DATA%" lacks ^(never overwriting^) ...
robocopy "%LINK%" "%DATA%" /E /XC /XN /XO /XJ /R:1 /W:1 /NFL /NDL /NJH /NP >nul
if %ERRORLEVEL% GEQ 8 (
  echo  STOP: the copy reported errors ^(robocopy %ERRORLEVEL%^). Nothing moved, link unchanged.
  goto :fail
)
echo    2^) moving it aside as "%ASIDE%" ^(kept, not deleted^) ...
move "%LINK%" "%ASIDE%" >nul || (
  echo  STOP: could not move "%LINK%" aside. Nothing deleted, link unchanged.
  goto :fail
)
goto :link

:firstuse
if not exist "%LINK%\bin\Custom\" (
  echo  STOP: "%LINK%" does not look like NinjaTrader data ^(no bin\Custom^).
  goto :fail
)
echo  STATE: FIRST USE - moving "%LINK%" to "%DATA%" ...
move "%LINK%" "%DATA%" >nul
if exist "%DATA%\bin\Custom\" goto :link
REM Different drives: move cannot rename across volumes, so copy, verify, then keep the original aside.
echo         different drives - copying instead ^(this can take a few minutes^) ...
robocopy "%LINK%" "%DATA%" /E /COPY:DAT /DCOPY:T /XJ /R:1 /W:1 /NFL /NDL /NJH /NP >nul
if %ERRORLEVEL% GEQ 8 (
  echo  STOP: the copy reported errors ^(robocopy %ERRORLEVEL%^). The original is untouched.
  goto :fail
)
if not exist "%DATA%\bin\Custom\" (
  echo  STOP: copy finished but "%DATA%\bin\Custom" is missing. The original is untouched.
  goto :fail
)
set "ASIDE=%DOCS%\NinjaTrader 8.migrated-%STAMP%"
move "%LINK%" "%ASIDE%" >nul || (
  echo  STOP: copied, but could not move the original aside. Link unchanged.
  goto :fail
)
echo         original kept as "%ASIDE%" - delete it yourself once NinjaTrader runs happily.
goto :link

:unlink
tasklist /FI "IMAGENAME eq NinjaTrader.exe" 2>nul | find /I "NinjaTrader.exe" >nul && (
  echo  STOP: NinjaTrader is running. Close it ^(File ^> Exit^) and run this again.
  goto :fail
)
echo  STATE: LINKED - unlinking so an installer meets a plain folder.
echo    1^) removing the junction ^(the link only; the data is untouched^) ...
rmdir "%LINK%" || (
  echo  STOP: could not remove the junction. Nothing changed.
  goto :fail
)
if exist "%LINK%\" (
  echo  STOP: "%LINK%" still exists after removing the link. Nothing moved.
  goto :fail
)
echo    2^) renaming "%DATA%" to "%LINK%" ...
move "%DATA%" "%LINK%" >nul || (
  echo  STOP: the rename failed. Re-creating the junction so nothing changes.
  echo        "Access is denied" means this needs administrator rights: the data
  echo        folder sits at the root of C:. Right-click this file, Run as administrator,
  echo        or use NinjaTrader8_1_BeforeUpdate.bat, which elevates itself.
  mklink /J "%LINK%" "%DATA%" >nul
  goto :fail
)
if not exist "%LINK%\bin\Custom\" (
  echo  STOP: renamed, but bin\Custom is not where it should be. Check both folders.
  goto :fail
)
echo  DONE: "%LINK%" is now a plain folder holding all your NinjaTrader data.
echo        Run the NinjaTrader installer. When it has finished, run this script
echo        again ^(or launch through the launcher^) and the junction comes back.
goto :ok

:link
mklink /J "%LINK%" "%DATA%" >nul || (
  echo  STOP: mklink failed.
  goto :fail
)
call :detect
if /I not "%LTYPE%"=="Junction" (
  echo  STOP: the link did not come up as a junction.
  goto :fail
)
if /I not "%TARGET%"=="%DATA%" (
  echo  STOP: the junction points at "%TARGET%".
  goto :fail
)
if not exist "%LINK%\bin\Custom\" (
  echo  STOP: junction created, but bin\Custom is not visible through it.
  goto :fail
)
echo  DONE: "%LINK%" now points at "%DATA%".
goto :ok

:detect
for /f "usebackq tokens=1,* delims=|" %%A in (`powershell -NoProfile -Command "$i = Get-Item -LiteralPath '%LINK%' -Force -ErrorAction SilentlyContinue; if ($i) { $t = if ($i.LinkType) { $i.LinkType } else { 'Directory' }; $t + '|' + ($i.Target -join ',') } else { 'Missing|' }"`) do (set "LTYPE=%%A" & set "TARGET=%%B")
exit /b 0

:ok
if not defined QUIET pause
exit /b 0

:fail
if not defined QUIET pause
exit /b 1
