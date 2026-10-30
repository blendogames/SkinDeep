@echo off
setlocal
cd /d "%~dp0"

call "%~dp0setup_stbrielle_runtime.bat"
if errorlevel 1 exit /b 1

if not exist "stbrielle.exe" (
    echo.
    echo ST. BRIELLE executable not found.
    echo Build solution\monstergame.sln using the stbrielle project first.
    echo.
    exit /b 1
)

set "SBROOT=%CD%"
set "SBSAVE=%APPDATA%\StBrielle\stbrielle"

if exist "%SBROOT%\stbrielle\maps\sb_dev_recordlab.proc" del /q "%SBROOT%\stbrielle\maps\sb_dev_recordlab.proc"
if exist "%SBROOT%\stbrielle\maps\sb_dev_recordlab.cm" del /q "%SBROOT%\stbrielle\maps\sb_dev_recordlab.cm"
if exist "%SBROOT%\stbrielle\maps\sb_dev_recordlab02.proc" del /q "%SBROOT%\stbrielle\maps\sb_dev_recordlab02.proc"
if exist "%SBROOT%\stbrielle\maps\sb_dev_recordlab02.cm" del /q "%SBROOT%\stbrielle\maps\sb_dev_recordlab02.cm"

echo.
echo Compiling St. Brielle Record Laboratory maps...
echo Base path: %SBROOT%
echo Dev path:  %SBROOT%
echo.

stbrielle.exe +set fs_basepath "%SBROOT%" +set fs_devpath "%SBROOT%" +set fs_game stbrielle +set developer 1 +set r_clear 2 +set con_noPrint 1 +set com_showFPS 0 +set fs_copyfiles 0 +set si_pure 0 +dmap2 sb_dev_recordlab +dmap2 sb_dev_recordlab02 +quit

if exist "%SBSAVE%\qconsole.log" copy /y "%SBSAVE%\qconsole.log" "%SBROOT%\recordlab_compile.log" >nul

if not exist "%SBROOT%\stbrielle\maps\sb_dev_recordlab.proc" (
    echo.
    echo ERROR: sb_dev_recordlab.proc was not created.
    echo Expected:
    echo   %SBROOT%\stbrielle\maps\sb_dev_recordlab.proc
    echo.
    echo See recordlab_compile.log for the dmap output.
    echo.
    pause
    exit /b 1
)

if not exist "%SBROOT%\stbrielle\maps\sb_dev_recordlab.cm" (
    echo.
    echo ERROR: sb_dev_recordlab.cm was not created.
    echo See recordlab_compile.log for the dmap output.
    echo.
    pause
    exit /b 1
)

if not exist "%SBROOT%\stbrielle\maps\sb_dev_recordlab02.proc" (
    echo.
    echo ERROR: sb_dev_recordlab02.proc was not created.
    echo See recordlab_compile.log for the dmap output.
    echo.
    pause
    exit /b 1
)

if not exist "%SBROOT%\stbrielle\maps\sb_dev_recordlab02.cm" (
    echo.
    echo ERROR: sb_dev_recordlab02.cm was not created.
    echo See recordlab_compile.log for the dmap output.
    echo.
    pause
    exit /b 1
)

echo.
echo Compile verified:
echo   stbrielle\maps\sb_dev_recordlab.proc
echo   stbrielle\maps\sb_dev_recordlab.cm
echo   stbrielle\maps\sb_dev_recordlab02.proc
echo   stbrielle\maps\sb_dev_recordlab02.cm
echo.
echo Launching St. Brielle Record Laboratory...

stbrielle.exe +set fs_basepath "%SBROOT%" +set fs_devpath "%SBROOT%" +set fs_game stbrielle +set developer 1 +set r_clear 2 +set con_noPrint 1 +set com_showFPS 0 +set fs_copyfiles 0 +set si_pure 0 +devmap sb_dev_recordlab

if exist "%SBSAVE%\qconsole.log" copy /y "%SBSAVE%\qconsole.log" "%SBROOT%\recordlab_runtime.log" >nul

endlocal
