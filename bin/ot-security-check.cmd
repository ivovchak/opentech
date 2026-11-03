@echo off
rem Check for the svc-telemetry SSH key planted by the compromised Claude Code extension in the Cursor marketplace
rem Details and cleanup scripts: https://cursor.com/blog/claude-code-extension-security-notice
powershell -NoProfile -Command "$f = @(\"$HOME\.ssh\authorized_keys\", \"$env:ProgramData\ssh\administrators_authorized_keys\") | Where-Object { Test-Path $_ }; if ($f -and (Select-String -Path $f -Pattern 'svc-telemetry' -SimpleMatch -Quiet)) { 'FOUND' } else { 'clean' }"
