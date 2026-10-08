# Remove separate Claude Code + VS Code for Windows
# Run: double-click uninstall.cmd
#      or: powershell -ExecutionPolicy Bypass -File uninstall.ps1 [-Yes]
#   -Yes  also delete the folder with logins and settings without asking

param([switch]$Yes)

$ErrorActionPreference = 'Stop'
$OT     = $PSScriptRoot
$BinDir = Join-Path $OT 'bin'

Write-Host ""
Write-Host "Removing separate tools from $OT" -ForegroundColor Cyan
Write-Host ""

# 1. Remove bin from the user PATH
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (-not $userPath) { $userPath = '' }
$parts = @($userPath -split ';' | Where-Object { $_ -ne '' })
if ($parts -contains $BinDir) {
    $rest = @($parts | Where-Object { $_ -ne $BinDir })
    [Environment]::SetEnvironmentVariable('Path', ($rest -join ';'), 'User')
    Write-Host "[-] Removed $BinDir from PATH"
} else {
    Write-Host "[=] $BinDir is not in PATH"
}

# 2. Desktop shortcut
$lnkPath = Join-Path ([Environment]::GetFolderPath('Desktop')) 'ot-code.lnk'
if (Test-Path $lnkPath) {
    Remove-Item -Force $lnkPath
    Write-Host "[-] Removed the ot-code desktop shortcut"
}

# 3. Folder with logins, settings, and this repository
if (-not $Yes) {
    Write-Warning "$OT contains the dedicated login (claude\) and ot-code settings (vscode\)."
    $answer = Read-Host "Delete $OT completely? [y/N]"
    $Yes = $answer -match '^[yY]'
}
if ($Yes) {
    Set-Location $HOME
    try {
        Remove-Item -Recurse -Force $OT
        Write-Host "[-] Removed $OT"
    } catch {
        Write-Warning "Could not delete $OT completely. Close ot-code and ot-claude, then delete the folder manually."
    }
} else {
    Write-Host "[=] Kept $OT (delete it manually if no longer needed)"
}

Write-Host ""
Write-Host "Done! Open a NEW terminal for PATH changes to take effect." -ForegroundColor Green
Write-Host ""
