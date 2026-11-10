@echo off
rem Claude desktop app with the dedicated account.
rem A second copy of Claude that keeps its data in profiles\claude-desktop, so it runs
rem side by side with your personal Claude. Its Code tab uses profiles\claude-code (same as ot-claude).
setlocal
for %%I in ("%~dp0..") do set "OT_HOME=%%~fI"
set "CLAUDE_CONFIG_DIR=%OT_HOME%\profiles\claude-code"
set "ANTHROPIC_API_KEY="
set "DATA=%OT_HOME%\profiles\claude-desktop"
set "CLAUDE_EXE=%LOCALAPPDATA%\AnthropicClaude\claude.exe"
if not exist "%CLAUDE_EXE%" set "CLAUDE_EXE=%LOCALAPPDATA%\Programs\Claude\Claude.exe"
if not exist "%CLAUDE_EXE%" set "CLAUDE_EXE=%ProgramFiles%\Claude\Claude.exe"
if not exist "%CLAUDE_EXE%" goto :noclaude
if not exist "%DATA%" mkdir "%DATA%"
rem With its own data folder Claude does not stop a second copy, and two copies on one folder
rem can corrupt it. If it is already running, do not start another one.
powershell -NoProfile -Command "$d = $env:DATA; if (Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'claude.exe' -and $_.CommandLine -and $_.CommandLine.Contains($d) }) { exit 1 }"
if errorlevel 1 (
  echo OT Claude is already running.
  exit /b 0
)
start "" "%CLAUDE_EXE%" --user-data-dir="%DATA%" %*
exit /b 0

:noclaude
echo Claude desktop app not found. Install it from https://claude.ai/download
echo The Microsoft Store version is not supported: it does not accept a separate data folder.
pause
exit /b 1
