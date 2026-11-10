#!/usr/bin/env bash
# Remove the isolated Claude Code + VS Code profile for macOS / Linux
# Run: bash uninstall.sh [--yes]
#   --yes  also delete the folder with logins and settings without asking
set -euo pipefail

OT_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
warn() { printf '\033[33m[!] %s\033[0m\n' "$*"; }

YES=0
[ "${1:-}" = "--yes" ] && YES=1

printf '\n\033[36mRemoving the isolated profile from %s\033[0m\n\n' "$OT_HOME"

# 1. Remove bin from PATH
MARK="# opentech-bin"
for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
  [ -f "$rc" ] || continue
  if grep -qF "$MARK" "$rc"; then
    tmp="$(mktemp)"
    grep -vF "$MARK" "$rc" > "$tmp" || true
    cat "$tmp" > "$rc"
    rm -f "$tmp"
    echo "[-] Removed PATH entry from $rc"
  else
    echo "[=] No PATH entry in $rc"
  fi
done

# 2. Launch shortcuts
case "$(uname -s)" in
  Darwin) SHORTCUTS=("$HOME/Applications/VS Code OpenTech.app" "$HOME/Applications/OT Claude.app" "$HOME/Applications/Claude OpenTech.app") ;;
  Linux)  SHORTCUTS=("$HOME/.local/share/applications/ot-code.desktop") ;;
  *)      SHORTCUTS=() ;;
esac
for s in ${SHORTCUTS[@]+"${SHORTCUTS[@]}"}; do
  if [ -e "$s" ]; then
    rm -rf "$s"
    echo "[-] Removed $s"
  fi
done

# 3. Folder with logins, settings, and this repository
if [ "$YES" -eq 0 ] && [ -t 0 ]; then
  warn "$OT_HOME contains the dedicated logins and settings (profiles/)."
  read -r -p "Delete $OT_HOME completely? [y/N] " answer
  case "$answer" in [yY]*) YES=1 ;; esac
fi
if [ "$YES" -eq 1 ]; then
  cd "$HOME"
  rm -rf "$OT_HOME"
  echo "[-] Removed $OT_HOME"
else
  echo "[=] Kept $OT_HOME (delete it manually if no longer needed)"
fi

printf '\n\033[32mDone! Open a NEW terminal for PATH changes to take effect.\033[0m\n\n'
