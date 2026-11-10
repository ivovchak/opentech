# 0001: move claude\, claude-api\ and vscode\ into profiles\
#   claude\     -> profiles\claude-code\
#   claude-api\ -> profiles\claude-code-api\
#   vscode\     -> profiles\vscode\
# Also fixes absolute paths in JSON files. On Windows the Claude Code login is a file
# inside the folder (.credentials.json), so it moves together with the folder.
param([Parameter(Mandatory)][string]$OT)

$ErrorActionPreference = 'Stop'
$P = Join-Path $OT 'profiles'
New-Item -ItemType Directory -Force -Path $P | Out-Null

$pairs = [ordered]@{ 'claude' = 'claude-code'; 'claude-api' = 'claude-code-api'; 'vscode' = 'vscode' }

# Refuse to move folders that are in use
$vsOld = Join-Path $OT 'vscode'
$running = Get-CimInstance Win32_Process -Filter "Name = 'Code.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -and $_.CommandLine.Contains($vsOld) }
if ($running) { throw "VS Code OpenTech (ot-code) is running. Close it and run install.cmd again." }

$moved = @()
foreach ($old in $pairs.Keys) {
    $new = $pairs[$old]
    $src = Join-Path $OT $old
    $dst = Join-Path $P $new
    if (-not (Test-Path $src)) { continue }
    if ((Test-Path $dst) -and (Get-ChildItem -Force $dst | Select-Object -First 1)) {
        throw "Both $src and $dst exist; merge them manually and run install.cmd again."
    }
    if (Test-Path $dst) { Remove-Item -Force $dst }
    try { Move-Item -Path $src -Destination $dst }
    catch { throw "Could not move $src (is ot-claude or ot-code still running?). $_" }
    Write-Host "    moved $old\ -> profiles\$new\"
    $moved += $old
}
if (-not $moved) { return }

# Paths in JSON may be written as C:\x, C:\\x (escaped), C:/x, /c:/x or /c%3A/x (URIs).
# Match the .opentech folder in any of these forms and keep the separator style.
$rel  = $OT.Substring(3) -split '\\' | ForEach-Object { [regex]::Escape($_) }
$sep  = '(?<s>\\\\|\\|/)'
$base = '(?<base>/?' + [regex]::Escape($OT.Substring(0, 1)) + '(?::|%3A)' + $sep + ($rel -join '\k<s>') + ')\k<s>'
$rules = @(
    @{ re = "(?i)$base" + 'claude-api(?=[\\/"]|$)'; to = '${base}${s}profiles${s}claude-code-api' },
    @{ re = "(?i)$base" + 'claude(?=[\\/"]|$)';     to = '${base}${s}profiles${s}claude-code' },
    @{ re = "(?i)$base" + 'vscode(?=[\\/"]|$)';     to = '${base}${s}profiles${s}vscode' }
)
$utf8 = New-Object Text.UTF8Encoding $false
Get-ChildItem -Path $P -Recurse -File -Filter '*.json' -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '\\(projects|Cache[^\\]*|node_modules)\\' } |
    ForEach-Object {
        $text = [IO.File]::ReadAllText($_.FullName)
        $new  = $text
        foreach ($r in $rules) { $new = [regex]::Replace($new, $r.re, $r.to) }
        if ($new -ne $text) {
            [IO.File]::WriteAllText($_.FullName, $new, $utf8)
            Write-Host "    fixed paths in $($_.FullName.Substring($OT.Length + 1))"
        }
    }
