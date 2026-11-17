@echo off
rem Old name of ot-vscode (VS Code with the dedicated Claude account); passes everything on to it.
call "%~dp0ot-vscode.cmd" %*
exit /b %errorlevel%
