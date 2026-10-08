@echo off
rem Everything on one line: the script deletes its own folder, so cmd must not read further lines
cd /d "%USERPROFILE%" & powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1" & pause & exit /b
