@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0make-mod.ps1"
set "EXIT_CODE=%ERRORLEVEL%"
if not "%EXIT_CODE%"=="0" (
    echo.
    echo [ERROR] ApexCombat AI build failed with exit code %EXIT_CODE%.
    pause
    exit /b %EXIT_CODE%
)
echo.
echo [SUCCESS] ApexCombat AI build completed and verified in READY-MOD\ApexCombat-AI-1.21.11.jar.
pause
exit /b 0
