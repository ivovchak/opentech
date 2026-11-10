@echo off
setlocal
for %%I in ("%~dp0..") do set "OT_HOME=%%~fI"
set "CLAUDE_CONFIG_DIR=%OT_HOME%\profiles\claude-code"
set "ANTHROPIC_API_KEY="
claude %*
