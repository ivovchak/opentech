@echo off
rem Claude Code billed to the Anthropic API key (pay per token) instead of the subscription
rem The key is read from %OT_HOME%\anthropic-api-key (git-ignored) or from OT_ANTHROPIC_API_KEY
setlocal
for %%I in ("%~dp0..") do set "OT_HOME=%%~fI"
set "KEY_FILE=%OT_HOME%\anthropic-api-key"

set "ANTHROPIC_API_KEY=%OT_ANTHROPIC_API_KEY%"
if not defined ANTHROPIC_API_KEY if exist "%KEY_FILE%" set /p ANTHROPIC_API_KEY=<"%KEY_FILE%"
if not defined ANTHROPIC_API_KEY (
  echo API key not found. Save it as a single line in "%KEY_FILE%" 1>&2
  exit /b 1
)

set "CLAUDE_CONFIG_DIR=%OT_HOME%\profiles\claude-code-api"
claude %*
