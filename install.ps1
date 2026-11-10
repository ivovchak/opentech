# Isolated Claude Code + VS Code profile for Windows
# Run: double-click install.cmd
#      or: powershell -ExecutionPolicy Bypass -File install.ps1

$ErrorActionPreference = 'Stop'
$OT        = $PSScriptRoot
$P            = Join-Path $OT 'profiles'
$ClaudeDir    = Join-Path $P 'claude-code'
$ClaudeApiDir = Join-Path $P 'claude-code-api'
$DesktopDir   = Join-Path $P 'claude-desktop'
$DataDir      = Join-Path $P 'vscode\data'
$ExtDir       = Join-Path $P 'vscode\extensions'
$BinDir       = Join-Path $OT 'bin'
$Version      = if (Test-Path (Join-Path $OT 'VERSION')) { (Get-Content (Join-Path $OT 'VERSION') -TotalCount 1).Trim() } else { 'unknown' }

Write-Host ""
Write-Host "Installing OpenTech $Version to $OT" -ForegroundColor Cyan
Write-Host ""

# 0. Migrations: one-time changes to existing data (see migrations\ and CHANGELOG.md).
# Applied migration names are recorded in profiles\.migrations so each runs only once.
New-Item -ItemType Directory -Force -Path $P | Out-Null
$applied = Join-Path $P '.migrations'
if (-not (Test-Path $applied)) { New-Item -ItemType File -Path $applied | Out-Null }
$done = @(Get-Content $applied)
foreach ($m in Get-ChildItem (Join-Path $OT 'migrations') -Filter '[0-9]*.ps1' | Sort-Object Name) {
    $name = $m.BaseName
    if ($done -contains $name) { continue }
    Write-Host "[..] Migration $name"
    try { & $m.FullName -OT $OT }
    catch {
        Write-Warning "Migration $name failed: $($_.Exception.Message)"
        Write-Warning "Fix the problem above and run install.cmd again."
        exit 1
    }
    Add-Content -Path $applied -Value $name
    Write-Host "[+] Migration $name applied"
}

# 1. Directories
foreach ($d in @($ClaudeDir, $ClaudeApiDir, $DesktopDir, (Join-Path $DataDir 'User'), $ExtDir)) {
    New-Item -ItemType Directory -Force -Path $d | Out-Null
}
Write-Host "[+] profiles\ (claude-code, claude-code-api, claude-desktop, vscode) is ready"

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

# 5b. Claude desktop shortcut (a second Claude with the dedicated account)
Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $desktop 'Claude OpenTech.lnk')  # old name (2.0.0)
$ClaudeExe = @(
    (Join-Path $env:LOCALAPPDATA 'AnthropicClaude\claude.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\Claude\Claude.exe'),
    (Join-Path $env:ProgramFiles 'Claude\Claude.exe')
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($ClaudeExe) {
    $lnk = $shell.CreateShortcut((Join-Path $desktop 'OT Claude.lnk'))
    $lnk.TargetPath       = Join-Path $BinDir 'ot-claude-desktop.cmd'
    $lnk.WorkingDirectory = $OT
    $lnk.WindowStyle      = 7
    $lnk.Description      = 'Claude desktop with the dedicated account'
    $lnk.IconLocation     = "$ClaudeExe,0"
    $lnk.Save()
    Write-Host "[+] OT Claude shortcut created on the desktop"
} elseif (Get-AppxPackage -Name '*Claude*' -ErrorAction SilentlyContinue) {
    Write-Warning "Claude is installed from the Microsoft Store; that version cannot use a separate data folder. Install it from https://claude.ai/download to get OT Claude."
} else {
    Write-Warning "Claude desktop app not found; install it from https://claude.ai/download and run install.cmd again."
}

# 6. Claude Code CLI
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Warning "Claude Code CLI not found. Install it with: irm https://claude.ai/install.ps1 | iex"
}

# 7. Security checks (see security\README.md)
Write-Host ""
Write-Host "Security checks" -ForegroundColor Cyan
$key = & (Join-Path $BinDir 'ot-security-check.cmd')
Write-Host "SSH backdoor key (svc-telemetry): $key"
if (Get-Command php -ErrorAction SilentlyContinue) {
    & php (Join-Path $OT 'security\check-php.php')
    if ($LASTEXITCODE -ne 0) { Write-Warning "PHP check failed, see security\README.md" }
}
if (Get-Command node -ErrorAction SilentlyContinue) {
    & node (Join-Path $OT 'security\check-node.js')
    if ($LASTEXITCODE -ne 0) { Write-Warning "Node.js check failed, see security\README.md" }
}

Write-Host ""
Write-Host "Done! Next steps:" -ForegroundColor Green
Write-Host "  1. Open a NEW terminal and run: ot-claude"
Write-Host "  2. Sign in with the dedicated account and verify with /status"
Write-Host "  3. Open dedicated projects only through the VS Code OpenTech shortcut"
Write-Host "  4. Claude desktop with the dedicated account: the OT Claude shortcut"
Write-Host "  Update later with: ot-update"
Write-Host ""
