@echo off
setlocal
cd /d "%~dp0"
if exist "gradlew.bat" (
    call gradlew.bat clean build --no-daemon
) else (
    call gradle clean build --no-daemon
)
exit /b %ERRORLEVEL%
