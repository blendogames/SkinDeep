@echo off
setlocal
cd /d "%~dp0"

echo.
echo ST. BRIELLE runtime dependency setup
echo Repository: %CD%
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\setup_stbrielle_runtime.ps1"
if errorlevel 1 (
    echo.
    echo Runtime dependency setup FAILED.
    echo.
    if exist "%~dp0stbrielle_runtime_setup.log" (
        echo Last log lines:
        echo ------------------------------------------------------------
        powershell.exe -NoProfile -Command "Get-Content -Path '%~dp0stbrielle_runtime_setup.log' -Tail 30"
        echo ------------------------------------------------------------
    )
    echo.
    echo Press any key to close this window.
    pause >nul
    exit /b 1
)

echo.
echo Runtime dependencies are ready beside stbrielle.exe.
echo.
endlocal
