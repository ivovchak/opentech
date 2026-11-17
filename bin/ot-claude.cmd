@echo off
setlocal
for %%I in ("%~dp0..") do set "OT_HOME=%%~fI"
set "CLAUDE_CONFIG_DIR=%OT_HOME%\profiles\claude-code"
set "ANTHROPIC_API_KEY="
rem The native install (kept current by ot-update) wins over whatever comes first in PATH
set "CLAUDE=claude"
if exist "%USERPROFILE%\.local\bin\claude.exe" set "CLAUDE=%USERPROFILE%\.local\bin\claude.exe"
"%CLAUDE%" %*
