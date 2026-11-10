@echo off
rem Update OpenTech: pull the latest version and re-run install.ps1 (which applies new migrations).
setlocal
for %%I in ("%~dp0..") do set "OT_HOME=%%~fI"
set /p OLD=<"%OT_HOME%\VERSION"
git -C "%OT_HOME%" pull --ff-only || exit /b 1
set /p NEW=<"%OT_HOME%\VERSION"
if "%OLD%"=="%NEW%" (echo OpenTech %NEW% is up to date) else (echo OpenTech %OLD% -^> %NEW% ^(see CHANGELOG.md^))
powershell -NoProfile -ExecutionPolicy Bypass -File "%OT_HOME%\install.ps1"
