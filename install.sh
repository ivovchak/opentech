#!/usr/bin/env bash
# Isolated Claude Code + VS Code profile for macOS / Linux
# Run: bash install.sh
set -euo pipefail

OT_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$OT_HOME/bin"
warn() { printf '\033[33m[!] %s\033[0m\n' "$*"; }

P="$OT_HOME/profiles"
VERSION="$(cat "$OT_HOME/VERSION" 2>/dev/null || echo unknown)"

printf '\n\033[36mInstalling OpenTech %s to %s\033[0m\n\n' "$VERSION" "$OT_HOME"

# 0. Migrations: one-time changes to existing data (see migrations/ and CHANGELOG.md).
# Applied migration names are recorded in profiles/.migrations so each runs only once.
mkdir -p "$P"
APPLIED="$P/.migrations"
touch "$APPLIED"
for m in "$OT_HOME"/migrations/[0-9]*.sh; do
  [ -f "$m" ] || continue
  name="$(basename "$m" .sh)"
  grep -qxF "$name" "$APPLIED" && continue
  echo "[..] Migration $name"
  if bash "$m" "$OT_HOME"; then
    echo "$name" >> "$APPLIED"
    echo "[+] Migration $name applied"
  else
    warn "Migration $name failed. Fix the problem above and run install.sh again."
    exit 1
  fi
done

# 1. Directories and permissions
mkdir -p "$P/claude-code" "$P/claude-code-api" "$P/claude-desktop" "$P/vscode/data/User" "$P/vscode/extensions"
chmod 700 "$P"
chmod +x "$BIN"/ot-* "$OT_HOME"/migrations/*.sh
echo "[+] profiles/ (claude-code, claude-code-api, claude-desktop, vscode) is ready"
[ -f "$OT_HOME/anthropic-api-key" ] && chmod 600 "$OT_HOME/anthropic-api-key"

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
SETTINGS="$P/vscode/data/User/settings.json"
if [ ! -f "$SETTINGS" ]; then
  sed "s|__CLAUDE_CONFIG_DIR__|$P/claude-code|g" "$OT_HOME/templates/settings.json" > "$SETTINGS"
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

# 5. Launch shortcuts
# make_app NAME COMMAND [ICON]: a small ~/Applications/NAME.app that runs COMMAND
make_app() {
  local app="$HOME/Applications/$1.app"
  rm -rf "$app"
  osacompile -o "$app" -e "do shell script quoted form of \"$2\" & \" > /dev/null 2>&1 &\"" 2>/dev/null || return 1
  if [ -n "${3:-}" ] && [ -f "$3" ]; then
    cp "$3" "$app/Contents/Resources/applet.icns"
    codesign --force --sign - "$app" >/dev/null 2>&1 || true
    touch "$app"
  fi
}
case "$(uname -s)" in
  Darwin)
    mkdir -p "$HOME/Applications"
    if make_app "VS Code OpenTech" "$BIN/ot-code"; then
      echo "[+] VS Code OpenTech app created in ~/Applications"
    else
      warn "Could not create the shortcut; launch with: ot-code"
    fi
    rm -rf "$HOME/Applications/Claude OpenTech.app"  # old name (2.0.0)
    CLAUDE_APP=""
    for a in "/Applications/Claude.app" "$HOME/Applications/Claude.app"; do
      [ -d "$a" ] && CLAUDE_APP="$a" && break
    done
    if [ -z "$CLAUDE_APP" ]; then
      warn "Claude desktop app not found; install it from https://claude.ai/download and run install.sh again"
    elif make_app "OT Claude" "$BIN/ot-claude-desktop" "$CLAUDE_APP/Contents/Resources/electron.icns"; then
      echo "[+] OT Claude app created in ~/Applications"
    else
      warn "Could not create the shortcut; launch with: ot-claude-desktop"
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

# 7. Security checks (see security/README.md)
printf '\n\033[36mSecurity checks\033[0m\n'
echo "SSH backdoor key (svc-telemetry): $("$BIN/ot-security-check")"
if command -v php >/dev/null 2>&1; then php "$OT_HOME/security/check-php.php" || warn "PHP check failed, see security/README.md"; fi
if command -v node >/dev/null 2>&1; then node "$OT_HOME/security/check-node.js" || warn "Node.js check failed, see security/README.md"; fi

printf '\n\033[32mDone! Next steps:\033[0m\n'
echo "  1. Open a NEW terminal and run: ot-claude"
echo "  2. Sign in with the dedicated account and verify with /status"
echo "  3. Open dedicated projects with the VS Code OpenTech shortcut or the ot-code command"
[ "$(uname -s)" = "Darwin" ] && echo "  4. Claude desktop with the dedicated account: OT Claude in ~/Applications"
echo "  Update later with: ot-update"
echo
