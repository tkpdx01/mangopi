@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-mangopi.ps1"
exit /b %ERRORLEVEL%
