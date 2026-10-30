@echo off
setlocal
cd /d "%~dp0"

echo.
echo ============================================================
echo ST. BRIELLE - CONSOLE BUILD VERIFIER
echo ============================================================
echo Repository: %CD%
echo.

where git >nul 2>nul
if errorlevel 1 (
    echo ERROR: git.exe is not available in PATH.
    pause
    exit /b 1
)

for /f "delims=" %%G in ('git rev-parse --short HEAD 2^>nul') do set "SBHEAD=%%G"
echo Git HEAD: %SBHEAD%

git branch --show-current
echo.

findstr /C:"CONSOLE INPUT FIX 4 ACTIVE" "sys\events.cpp" >nul
if errorlevel 1 (
    echo ERROR: Your local sys\events.cpp does NOT contain FIX 4.
    echo Run:
    echo   git pull origin st-brielle-foundation
    echo.
    pause
    exit /b 1
) else (
    echo [OK] Local source contains CONSOLE INPUT FIX 4.
)

findstr /C:"CONSOLE INPUT FIX 3" "framework\Console.cpp" >nul
if errorlevel 1 (
    echo ERROR: Your local framework\Console.cpp does NOT contain the console patch.
    echo Run:
    echo   git pull origin st-brielle-foundation
    echo.
    pause
    exit /b 1
) else (
    echo [OK] Local Console.cpp contains the console patch.
)

echo.
if not exist "%CD%\stbrielle.exe" (
    echo ERROR: %CD%\stbrielle.exe does not exist.
    echo Open solution\monstergame.sln and Rebuild the stbrielle project.
    echo.
    pause
    exit /b 1
)

for %%F in ("%CD%\stbrielle.exe") do (
    echo Executable: %%~fF
    echo Built:      %%~tF
    echo Size:       %%~zF bytes
)

for %%F in ("%CD%\framework\Console.cpp") do echo Console.cpp modified: %%~tF
for %%F in ("%CD%\sys\events.cpp") do echo events.cpp modified:  %%~tF

echo.
echo IMPORTANT:
echo After pulling FIX 4, rebuild solution\monstergame.sln.
echo Then run this verifier again.
echo.
echo Launching EXACTLY:
echo   %CD%\stbrielle.exe
echo.
pause

"%CD%\stbrielle.exe" +set fs_basepath "%CD%" +set fs_devpath "%CD%" +set fs_game stbrielle +set developer 1 +set com_allowConsole 1 +set con_noPrint 0 +set fs_copyfiles 0 +set si_pure 0 +devmap sb_dev_recordlab

endlocal
