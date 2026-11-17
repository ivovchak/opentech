# Used by bin\ot-update.cmd when `git pull --ff-only` fails: the published history was rewritten
# (same files, new commit ids). Move to it only when that loses nothing: no local edits to tracked
# files, and the files of the current commit are part of the new history. profiles\ is git-ignored and is kept.
param([string]$OT)
$ErrorActionPreference = 'Stop'
git -C $OT diff --quiet HEAD
$clean = ($LASTEXITCODE -eq 0)
$tree = git -C $OT rev-parse 'HEAD^{tree}'
$trees = git -C $OT log '@{upstream}' --format=%T
if ($clean -and ($trees -contains $tree)) {
    Write-Host "[..] The OpenTech history was rewritten on GitHub; moving to it (your profiles\ are kept)"
    git -C $OT reset --hard '@{upstream}'
    exit $LASTEXITCODE
}
Write-Warning "Could not update: this copy has local changes. Keep what you need, then run:"
Write-Host "    cd `"$OT`"; git fetch; git reset --hard '@{upstream}'; bin\ot-update.cmd"
exit 1
