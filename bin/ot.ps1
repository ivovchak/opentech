# ot: Claude profiles, each with its own account (Claude Code + a Claude desktop copy). Windows version of bin/ot.
# Run: ot help   (bin\ot.cmd starts this script)
#
# A profile is a pair of folders in profiles\:
#   default -> claude-code\        + claude-desktop\         (ot-claude, OT Claude)
#   <name>  -> claude-code-<name>\ + claude-desktop-<name>\  (ot claude <name>, OT Claude <name>)
# claude-code-api\ belongs to ot-claude-api and is not a profile.

$ErrorActionPreference = 'Stop'
$OT  = Split-Path -Parent $PSScriptRoot
$P   = Join-Path $OT 'profiles'
$Bin = Join-Path $OT 'bin'
$Reserved = @('default', 'api', 'list', 'ls', 'add', 'rm', 'remove', 'help', 'desktop')

function Fail($msg) { [Console]::Error.WriteLine($msg); exit 1 }

function Show-Usage {
    @'
Usage:
  ot claude list              show profiles, their accounts and which desktop copies are running
  ot claude add NAME          create a profile (and an "OT Claude NAME" desktop shortcut)
  ot claude rm NAME [--yes]   delete a profile with its login, settings and chats
  ot claude [NAME] [ARGS]     Claude Code (terminal) with that profile
  ot claude [NAME] --app      Claude desktop app with that profile (the OT Claude NAME shortcut)
  ot vscode [NAME] [ARGS]     VS Code with that profile's Claude login

NAME: lowercase letters, digits and dashes; without NAME the default profile (ot-claude, OT Claude).
The product comes first (ot claude ...), so other AI tools can get their own `ot TOOL ...` later.
'@
}

function Get-CodeDir($n)    { if ($n -eq 'default') { Join-Path $P 'claude-code' }    else { Join-Path $P "claude-code-$n" } }
function Get-DesktopDir($n) { if ($n -eq 'default') { Join-Path $P 'claude-desktop' } else { Join-Path $P "claude-desktop-$n" } }
function Get-VsCodeDir($n)  { if ($n -eq 'default') { Join-Path $P 'vscode' }         else { Join-Path $P "vscode-$n" } }
function Get-AppName($n)    { if ($n -eq 'default') { 'OT Claude' } else { "OT Claude $n" } }
function Test-ValidName($n) { $n -cmatch '^[a-z0-9][a-z0-9-]{0,23}$' }

function Get-Profiles {
    'default'
    Get-ChildItem -Directory -Path $P -Filter 'claude-code-*' -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object {
        $n = $_.Name.Substring('claude-code-'.Length)
        if ((Test-ValidName $n) -and ($Reserved -notcontains $n)) { $n }
    }
}
function Test-Profile($n) {
    ($n -eq 'default') -or ((Test-ValidName $n) -and ($Reserved -notcontains $n) -and (Test-Path (Get-CodeDir $n)))
}
function Assert-Profile($n) {
    if (-not (Test-Profile $n)) { Fail "No profile '$n'. See: ot claude list; create it with: ot claude add $n" }
}

function Find-ClaudeExe {
    @(
        (Join-Path $env:LOCALAPPDATA 'AnthropicClaude\claude.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Claude\Claude.exe'),
        (Join-Path $env:ProgramFiles 'Claude\Claude.exe')
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
}

# The Claude desktop copy started on that data folder. Matched exactly, so claude-desktop
# does not also match claude-desktop-<name>.
function Get-DesktopProcess($data) {
    $re = '--user-data-dir="?' + [regex]::Escape($data) + '("|\s|$)'
    Get-CimInstance Win32_Process -Filter "Name = 'claude.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -and $_.CommandLine -match $re } | Select-Object -First 1
}

function Get-Account($dir) {
    $f = Join-Path $dir '.claude.json'
    if (-not (Test-Path $f)) { return '-' }
    $m = Select-String -Path $f -Pattern '"emailAddress":\s*"([^"]*)"' | Select-Object -First 1
    if ($m) { $m.Matches[0].Groups[1].Value } else { '-' }
}

function New-DesktopShortcut($n) {
    $exe = Find-ClaudeExe
    if (-not $exe) { return $false }
    $shell = New-Object -ComObject WScript.Shell
    $lnk = $shell.CreateShortcut((Join-Path ([Environment]::GetFolderPath('Desktop')) "$(Get-AppName $n).lnk"))
    $lnk.TargetPath       = Join-Path $Bin 'ot.cmd'
    $lnk.Arguments        = "claude $n --app"
    $lnk.WorkingDirectory = $OT
    $lnk.WindowStyle      = 7
    $lnk.Description      = "Claude desktop with the $n profile"
    $lnk.IconLocation     = "$exe,0"
    $lnk.Save()
    return $true
}

function Invoke-List {
    '{0,-20} {1,-9} {2}' -f 'PROFILE', 'DESKTOP', 'ACCOUNT'
    foreach ($n in Get-Profiles) {
        $desktop = if (Get-DesktopProcess (Get-DesktopDir $n)) { 'running' } else { '-' }
        '{0,-20} {1,-9} {2}' -f $n, $desktop, (Get-Account (Get-CodeDir $n))
    }
}

function Invoke-Add($a) {
    $n = $a | Select-Object -First 1
    if (-not $n) { Fail 'Usage: ot claude add NAME' }
    if (-not (Test-ValidName $n)) { Fail "Invalid name '$n': use lowercase letters, digits and dashes (up to 24), e.g. client-x" }
    if ($Reserved -contains $n) { Fail "'$n' is reserved; pick another name" }
    if (Test-Path (Get-CodeDir $n)) { Fail "Profile '$n' already exists" }
    New-Item -ItemType Directory -Force -Path (Get-CodeDir $n), (Get-DesktopDir $n) | Out-Null
    Write-Host "[+] Profile ${n}: profiles\claude-code-$n, profiles\claude-desktop-$n"
    if (New-DesktopShortcut $n) { Write-Host "[+] $(Get-AppName $n) shortcut created on the desktop" }
    else { Write-Warning 'Claude desktop app not found; Claude Code works, the desktop copy needs https://claude.ai/download' }
    Write-Host ''
    Write-Host "Next: sign in with this profile's account"
    Write-Host "  ot claude $n          (Claude Code; check /status)"
    Write-Host "  ot claude $n --app    (desktop app; quit other Claude windows while signing in)"
}

function Invoke-Remove($a) {
    $n = $null; $yes = $false
    foreach ($x in $a) {
        if ($x -eq '--yes' -or $x -eq '-y') { $yes = $true }
        elseif (-not $n) { $n = $x }
        else { Fail 'Usage: ot claude rm NAME [--yes]' }
    }
    if (-not $n) { Fail 'Usage: ot claude rm NAME [--yes]' }
    if ($n -eq 'default') { Fail 'The default profile is removed only by uninstall.cmd' }
    Assert-Profile $n
    if (Get-DesktopProcess (Get-DesktopDir $n)) { Fail "$(Get-AppName $n) is running; quit it first" }
    if (-not $yes) {
        Write-Warning "This deletes the login, settings, chats and session history of profile '$n'."
        if ((Read-Host "Delete profile '$n'? [y/N]") -notmatch '^[yY]') { Write-Host "[=] Kept profile $n"; return }
    }
    Remove-Item -Recurse -Force (Get-CodeDir $n), (Get-DesktopDir $n), (Get-VsCodeDir $n) -ErrorAction SilentlyContinue
    Write-Host "[-] Removed profiles\claude-code-$n, profiles\claude-desktop-$n and profiles\vscode-$n"
    $lnk = Join-Path ([Environment]::GetFolderPath('Desktop')) "$(Get-AppName $n).lnk"
    if (Test-Path $lnk) { Remove-Item -Force $lnk; Write-Host "[-] Removed the $(Get-AppName $n) desktop shortcut" }
}

function Invoke-Cli($n, $rest) {
    Assert-Profile $n
    $env:CLAUDE_CONFIG_DIR = Get-CodeDir $n
    Remove-Item Env:ANTHROPIC_API_KEY -ErrorAction SilentlyContinue
    # The native install (kept current by ot-update) wins over whatever comes first in PATH
    $claude = Join-Path $env:USERPROFILE '.local\bin\claude.exe'
    if (-not (Test-Path $claude)) { $claude = 'claude' }
    & $claude @rest
    exit $LASTEXITCODE
}

function Invoke-Desktop($n, $rest) {
    Assert-Profile $n
    $exe = Find-ClaudeExe
    if (-not $exe) {
        Fail "Claude desktop app not found. Install it from https://claude.ai/download`nThe Microsoft Store version is not supported: it does not accept a separate data folder."
    }
    $env:CLAUDE_CONFIG_DIR = Get-CodeDir $n
    Remove-Item Env:ANTHROPIC_API_KEY -ErrorAction SilentlyContinue
    $data = Get-DesktopDir $n
    New-Item -ItemType Directory -Force -Path $data | Out-Null
    # With its own data folder Claude does not stop a second copy, and two copies on one folder
    # can corrupt it. If it is already running, do not start another one.
    if (Get-DesktopProcess $data) { Write-Host "$(Get-AppName $n) is already running."; return }
    Start-Process -FilePath $exe -ArgumentList (@("--user-data-dir=`"$data`"") + @($rest))
}

# VS Code with its own settings and extensions (profiles\vscode[-NAME]) and the profile's Claude login
function Invoke-VsCode($n, $rest) {
    Assert-Profile $n
    $exe = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\Code.exe'),
        (Join-Path $env:ProgramFiles 'Microsoft VS Code\Code.exe')
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $exe) { Fail 'VS Code not found. Install it from https://code.visualstudio.com' }
    $cli = Join-Path (Split-Path -Parent $exe) 'bin\code.cmd'
    $env:CLAUDE_CONFIG_DIR = Get-CodeDir $n
    Remove-Item Env:ANTHROPIC_API_KEY -ErrorAction SilentlyContinue
    $dir = Get-VsCodeDir $n
    $user = Join-Path $dir 'data\User'
    New-Item -ItemType Directory -Force -Path $user, (Join-Path $dir 'extensions') | Out-Null
    $settings = Join-Path $user 'settings.json'
    if (-not (Test-Path $settings)) {
        $title = if ($n -eq 'default') { 'OpenTech' } else { "OpenTech $n" }
        $cfg = (Get-CodeDir $n).Replace('\', '\\')
        (Get-Content (Join-Path $OT 'templates\settings.json') -Raw).Replace('__CLAUDE_CONFIG_DIR__', $cfg).Replace('[OpenTech]', "[$title]") |
            Set-Content -Path $settings -Encoding UTF8
        Write-Host "[+] Created VS Code settings for profile $n"
    }
    $common = @('--user-data-dir', (Join-Path $dir 'data'), '--extensions-dir', (Join-Path $dir 'extensions'))
    if (-not (Get-ChildItem -Directory -Path (Join-Path $dir 'extensions') -Filter 'anthropic.claude-code-*' -ErrorAction SilentlyContinue)) {
        Write-Host "[..] Installing the Claude Code extension in VS Code for profile $n"
        & $cli @common --install-extension anthropic.claude-code | Out-Null
    }
    & $cli @common @rest
}

# --app right after the profile name opens the desktop app, otherwise Claude Code
function Invoke-Profile($n, $a) {
    $a = @($a)
    if ($a.Count -gt 0 -and $a[0] -eq '--app') { Invoke-Desktop $n @($a | Select-Object -Skip 1) }
    else { Invoke-Cli $n $a }
}

# After `claude` / `vscode`, the first argument is a profile name unless it is missing or an option
$cmd  = if ($args.Count -gt 0) { $args[0] } else { 'help' }
$rest = @($args | Select-Object -Skip 1)
switch ($cmd) {
    'claude' {
        $sub = $rest | Select-Object -First 1
        $more = @($rest | Select-Object -Skip 1)
        if ($sub -eq 'list' -or $sub -eq 'ls') { Invoke-List }
        elseif ($sub -eq 'add') { Invoke-Add $more }
        elseif ($sub -eq 'rm' -or $sub -eq 'remove') { Invoke-Remove $more }
        elseif (-not $sub -or $sub.StartsWith('-')) { Invoke-Profile 'default' $rest }
        else { Invoke-Profile $sub $more }
    }
    'vscode' {
        $sub = $rest | Select-Object -First 1
        if (-not $sub -or $sub.StartsWith('-')) { Invoke-VsCode 'default' $rest }
        else { Invoke-VsCode $sub @($rest | Select-Object -Skip 1) }
    }
    { $_ -in 'help', '-h', '--help' } { Show-Usage }
    default { [Console]::Error.WriteLine((Show-Usage)); exit 1 }
}
