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
set "SBGRAPHICS=graphics_balanced.cfg"
if /I "%~1"=="low" set "SBGRAPHICS=graphics_low.cfg"

echo.
echo Preparing Municipal Annex texture set...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\setup_annex_textures.ps1" -Root "%SBROOT%"
if errorlevel 1 (
    echo.
    echo ERROR: Municipal Annex textures could not be prepared.
    echo.
    pause
    exit /b 1
)

echo.
echo Preparing Room 214 corrected texture set...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\setup_room214_textures.ps1" -Root "%SBROOT%"
if errorlevel 1 (
    echo.
    echo ERROR: Room 214 corrected textures could not be prepared.
    echo.
    pause
    exit /b 1
)

echo.
echo Preparing Room 214 corrected ledger paper...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\setup_room214_paper.ps1" -Root "%SBROOT%"
if errorlevel 1 (
    echo.
    echo ERROR: Room 214 corrected ledger paper could not be prepared.
    echo.
    pause
    exit /b 1
)

echo.
echo Preparing Room 214 threshold sound...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\setup_room214_threshold_sound.ps1" -Root "%SBROOT%"
if errorlevel 1 (
    echo.
    echo ERROR: Room 214 threshold sound could not be prepared.
    echo.
    pause
    exit /b 1
)

if exist "%SBROOT%\stbrielle\maps\sb00_annex.proc" del /q "%SBROOT%\stbrielle\maps\sb00_annex.proc"
if exist "%SBROOT%\stbrielle\maps\sb00_annex.cm" del /q "%SBROOT%\stbrielle\maps\sb00_annex.cm"
if exist "%SBROOT%\stbrielle\maps\sb01_cityglimpse.proc" del /q "%SBROOT%\stbrielle\maps\sb01_cityglimpse.proc"
if exist "%SBROOT%\stbrielle\maps\sb01_cityglimpse.cm" del /q "%SBROOT%\stbrielle\maps\sb01_cityglimpse.cm"

echo.
echo Compiling Municipal Annex...
echo Base path: %SBROOT%
echo Dev path:  %SBROOT%
echo.

stbrielle.exe +set fs_basepath "%SBROOT%" +set fs_devpath "%SBROOT%" +set fs_game stbrielle +set developer 1 +set con_noPrint 1 +set com_showFPS 0 +set fs_copyfiles 0 +set si_pure 0 +bind e _frob +dmap2 sb00_annex +quit

if exist "%SBSAVE%\qconsole.log" copy /y "%SBSAVE%\qconsole.log" "%SBROOT%\annex_compile.log" >nul

if not exist "%SBROOT%\stbrielle\maps\sb00_annex.proc" (
    echo.
    echo ERROR: sb00_annex.proc was not created.
    echo See annex_compile.log for the dmap output.
    echo.
    pause
    exit /b 1
)

if not exist "%SBROOT%\stbrielle\maps\sb00_annex.cm" (
    echo.
    echo ERROR: sb00_annex.cm was not created.
    echo See annex_compile.log for the dmap output.
    echo.
    pause
    exit /b 1
)

echo.
echo Compiling St. Brielle city glimpse...
stbrielle.exe +set fs_basepath "%SBROOT%" +set fs_devpath "%SBROOT%" +set fs_game stbrielle +set developer 1 +set con_noPrint 1 +set com_showFPS 0 +set fs_copyfiles 0 +set si_pure 0 +bind e _frob +dmap2 sb01_cityglimpse +quit

if exist "%SBSAVE%\qconsole.log" copy /y "%SBSAVE%\qconsole.log" "%SBROOT%\cityglimpse_compile.log" >nul

if not exist "%SBROOT%\stbrielle\maps\sb01_cityglimpse.proc" (
    echo.
    echo ERROR: sb01_cityglimpse.proc was not created.
    echo See cityglimpse_compile.log for the dmap output.
    echo.
    pause
    exit /b 1
)

if not exist "%SBROOT%\stbrielle\maps\sb01_cityglimpse.cm" (
    echo.
    echo ERROR: sb01_cityglimpse.cm was not created.
    echo See cityglimpse_compile.log for the dmap output.
    echo.
    pause
    exit /b 1
)

echo.
echo Compile verified:
echo   stbrielle\maps\sb00_annex.proc
echo   stbrielle\maps\sb00_annex.cm
echo   stbrielle\maps\sb01_cityglimpse.proc
echo   stbrielle\maps\sb01_cityglimpse.cm
echo   stbrielle\textures\stbrielle\annex\*.tga
echo   stbrielle\skins\sb_room214.skin
echo   stbrielle\sound\annex\room214_threshold.wav
echo.
echo Launching Municipal Annex...
echo Interaction: E
echo Graphics: %SBGRAPHICS%
echo For lower rendering cost, launch run_stbrielle_annex.bat low
echo.

stbrielle.exe +set fs_basepath "%SBROOT%" +set fs_devpath "%SBROOT%" +set fs_game stbrielle +set developer 1 +set con_noPrint 1 +set com_showFPS 0 +set fs_copyfiles 0 +set si_pure 0 +bind e _frob +exec %SBGRAPHICS% +devmap sb00_annex

if exist "%SBSAVE%\qconsole.log" copy /y "%SBSAVE%\qconsole.log" "%SBROOT%\annex_runtime.log" >nul

endlocal
