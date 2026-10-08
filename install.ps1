# Isolated Claude Code + VS Code profile for Windows
# Run: double-click install.cmd
#      or: powershell -ExecutionPolicy Bypass -File install.ps1

$ErrorActionPreference = 'Stop'
$OT        = $PSScriptRoot
$ClaudeDir = Join-Path $OT 'claude'
$DataDir   = Join-Path $OT 'vscode\data'
$ExtDir    = Join-Path $OT 'vscode\extensions'
$BinDir    = Join-Path $OT 'bin'

Write-Host ""
Write-Host "Installing the isolated profile to $OT" -ForegroundColor Cyan
Write-Host ""

# 1. Directories
foreach ($d in @($ClaudeDir, (Join-Path $DataDir 'User'), $ExtDir)) {
    New-Item -ItemType Directory -Force -Path $d | Out-Null
}
Write-Host "[+] claude\ and vscode\ directories are ready"

# 2. Add bin to the user PATH (so the ot-claude command works)
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (-not $userPath) { $userPath = '' }
$parts = @($userPath -split ';' | Where-Object { $_ -ne '' })
if ($parts -notcontains $BinDir) {
    [Environment]::SetEnvironmentVariable('Path', (($parts + $BinDir) -join ';'), 'User')
    Write-Host "[+] Added $BinDir to PATH"
} else {
    Write-Host "[=] $BinDir is already in PATH"
}

# 3. Dedicated VS Code configuration
$settingsPath = Join-Path $DataDir 'User\settings.json'
if (-not (Test-Path $settingsPath)) {
    $tpl  = [IO.File]::ReadAllText((Join-Path $OT 'templates\settings.json'))
    $json = $tpl.Replace('__CLAUDE_CONFIG_DIR__', $ClaudeDir.Replace('\', '\\'))
    [IO.File]::WriteAllText($settingsPath, $json, (New-Object Text.UTF8Encoding $false))
    Write-Host "[+] Created settings.json for the dedicated VS Code instance"
} else {
    Write-Host "[=] settings.json already exists; leaving it unchanged"
}

# 4. VS Code and the Claude Code extension
$VsDir = @(
    (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code'),
    (Join-Path $env:ProgramFiles 'Microsoft VS Code')
) | Where-Object { Test-Path (Join-Path $_ 'Code.exe') } | Select-Object -First 1

if ($VsDir) {
    $CodeCli = Join-Path $VsDir 'bin\code.cmd'
    Write-Host "[..] Installing the Claude Code extension in the dedicated VS Code instance"
    & $CodeCli --user-data-dir $DataDir --extensions-dir $ExtDir --install-extension anthropic.claude-code --force
    if ($LASTEXITCODE -eq 0) { Write-Host "[+] Extension installed" }
    else { Write-Warning "Could not install the extension. Install it manually in the dedicated VS Code instance." }
} else {
    Write-Warning "VS Code not found. Install it from https://code.visualstudio.com and run install.cmd again."
}

# 5. Desktop shortcut
$desktop = [Environment]::GetFolderPath('Desktop')
$lnkPath = Join-Path $desktop 'VS Code OpenTech.lnk'
$shell   = New-Object -ComObject WScript.Shell
$lnk     = $shell.CreateShortcut($lnkPath)
$lnk.TargetPath       = Join-Path $BinDir 'ot-code.cmd'
$lnk.WorkingDirectory = $OT
$lnk.WindowStyle      = 7
$lnk.Description      = 'VS Code with the dedicated Claude account'
if ($VsDir) { $lnk.IconLocation = (Join-Path $VsDir 'Code.exe') + ',0' }
$lnk.Save()
Write-Host "[+] VS Code OpenTech shortcut created on the desktop"

# 6. Claude Code CLI
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Warning "Claude Code CLI not found. Install it with: irm https://claude.ai/install.ps1 | iex"
}

Write-Host ""
Write-Host "Done! Next steps:" -ForegroundColor Green
Write-Host "  1. Open a NEW terminal and run: ot-claude"
Write-Host "  2. Sign in with the dedicated account and verify with /status"
Write-Host "  3. Open dedicated projects only through the VS Code OpenTech shortcut"
Write-Host ""
