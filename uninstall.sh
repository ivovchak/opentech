#!/usr/bin/env bash
# Remove separate Claude Code + VS Code for macOS / Linux
# Run: bash uninstall.sh [--yes]
#   --yes  also delete the folder with logins and settings without asking
set -euo pipefail

OT_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
warn() { printf '\033[33m[!] %s\033[0m\n' "$*"; }

YES=0
[ "${1:-}" = "--yes" ] && YES=1

printf '\n\033[36mRemoving separate tools from %s\033[0m\n\n' "$OT_HOME"

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

# 2. Launch shortcut
case "$(uname -s)" in
  Darwin) SHORTCUT="$HOME/Applications/VS Code OT.app" ;;
  Linux)  SHORTCUT="$HOME/.local/share/applications/ot-vscode.desktop" ;;
  *)      SHORTCUT="" ;;
esac
if [ -n "$SHORTCUT" ] && [ -e "$SHORTCUT" ]; then
  rm -rf "$SHORTCUT"
  echo "[-] Removed $SHORTCUT"
fi

# 3. Folder with logins, settings, and this repository
if [ "$YES" -eq 0 ] && [ -t 0 ]; then
  warn "$OT_HOME contains the dedicated login (claude/) and VS Code OT settings (vscode/)."
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
