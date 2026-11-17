@echo off
rem ot: Claude profiles, each with its own account. Run: ot help (see bin\ot.ps1)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ot.ps1" %*
exit /b %errorlevel%
