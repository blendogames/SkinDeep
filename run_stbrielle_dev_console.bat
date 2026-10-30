@echo off
setlocal
cd /d "%~dp0"

if not exist "stbrielle.exe" (
    echo ST. BRIELLE executable not found in:
    echo   %CD%
    echo.
    echo Build solution\monstergame.sln first.
    pause
    exit /b 1
)

echo Launching ST. BRIELLE with the separate Windows developer console...
echo.
echo You should get TWO windows:
echo   1. The game window
echo   2. ST. BRIELLE Developer Console [SAFE INPUT]
echo.

stbrielle.exe +set fs_basepath "%CD%" +set fs_devpath "%CD%" +set fs_savepath "%CD%" +set fs_game stbrielle +set developer 1 +set com_allowConsole 1 +set win_viewlog 1 +set con_noPrint 0 +set fs_copyfiles 0 +set si_pure 0

endlocal
