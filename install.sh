#!/usr/bin/env bash
# Isolated Claude Code + VS Code profile for macOS / Linux
# Run: bash install.sh
set -euo pipefail

OT_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$OT_HOME/bin"
warn() { printf '\033[33m[!] %s\033[0m\n' "$*"; }

printf '\n\033[36mInstalling the isolated profile to %s\033[0m\n\n' "$OT_HOME"

# 1. Directories and permissions
mkdir -p "$OT_HOME/claude" "$OT_HOME/vscode/data/User" "$OT_HOME/vscode/extensions"
chmod +x "$BIN/ot-claude" "$BIN/ot-code"
echo "[+] claude/ and vscode/ directories are ready"

# 2. Add bin to PATH (so the ot-claude command works)
MARK="# opentech-bin"
LINE="export PATH=\"$BIN:\$PATH\" $MARK"
case "$(basename "${SHELL:-bash}")" in
  zsh) touch "$HOME/.zshrc" ;;
  *)   touch "$HOME/.bashrc" ;;
esac
for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
  [ -f "$rc" ] || continue
  if grep -qF "$MARK" "$rc"; then
    echo "[=] PATH is already configured in $rc"
  else
    printf '\n%s\n' "$LINE" >> "$rc"
    echo "[+] Added $BIN to PATH ($rc)"
  fi
done

# 3. Dedicated VS Code configuration
SETTINGS="$OT_HOME/vscode/data/User/settings.json"
if [ ! -f "$SETTINGS" ]; then
  sed "s|__CLAUDE_CONFIG_DIR__|$OT_HOME/claude|g" "$OT_HOME/templates/settings.json" > "$SETTINGS"
  echo "[+] Created settings.json for the dedicated VS Code instance"
else
  echo "[=] settings.json already exists; leaving it unchanged"
fi

# 4. Claude Code extension
echo "[..] Installing the Claude Code extension in the dedicated VS Code instance"
if "$BIN/ot-code" --install-extension anthropic.claude-code --force; then
  echo "[+] Extension installed"
else
  warn "Could not install the extension (is VS Code installed?). Run install.sh again later."
fi

# 5. Launch shortcut
case "$(uname -s)" in
  Darwin)
    mkdir -p "$HOME/Applications"
    if osacompile -o "$HOME/Applications/VS Code OpenTech.app" \
         -e "do shell script quoted form of \"$BIN/ot-code\" & \" > /dev/null 2>&1 &\"" 2>/dev/null; then
      echo "[+] VS Code OpenTech app created in ~/Applications"
    else
      warn "Could not create the shortcut; launch with: ot-code"
    fi
    ;;
  Linux)
    APPS="$HOME/.local/share/applications"
    mkdir -p "$APPS"
    cat > "$APPS/ot-code.desktop" <<EOF
[Desktop Entry]
Type=Application
  Name=VS Code OpenTech
  Comment=VS Code with the dedicated Claude account
Exec="$BIN/ot-code" %F
Icon=vscode
Terminal=false
Categories=Development;IDE;
EOF
    echo "[+] VS Code OpenTech shortcut added to the applications menu"
    ;;
esac

# 6. Claude Code CLI
if ! command -v claude >/dev/null 2>&1; then
  warn "Claude Code CLI not found. Install it with: curl -fsSL https://claude.ai/install.sh | bash"
fi

printf '\n\033[32mDone! Next steps:\033[0m\n'
echo "  1. Open a NEW terminal and run: ot-claude"
echo "  2. Sign in with the dedicated account and verify with /status"
echo "  3. Open dedicated projects with the VS Code OpenTech shortcut or the ot-code command"
echo
