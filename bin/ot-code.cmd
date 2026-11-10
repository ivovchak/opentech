@echo off
setlocal
for %%I in ("%~dp0..") do set "OT_HOME=%%~fI"
set "CLAUDE_CONFIG_DIR=%OT_HOME%\profiles\claude-code"
set "CODE_EXE=%LOCALAPPDATA%\Programs\Microsoft VS Code\Code.exe"
if not exist "%CODE_EXE%" set "CODE_EXE=%ProgramFiles%\Microsoft VS Code\Code.exe"
if not exist "%CODE_EXE%" goto :nocode
start "" "%CODE_EXE%" --user-data-dir "%OT_HOME%\profiles\vscode\data" --extensions-dir "%OT_HOME%\profiles\vscode\extensions" %*
exit /b 0

:nocode
echo VS Code not found. Install it from https://code.visualstudio.com
pause
exit /b 1
