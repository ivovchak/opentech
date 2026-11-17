#!/usr/bin/env bash
# Isolated Claude Code + VS Code profile for macOS / Linux
# Run: bash install.sh
set -euo pipefail

OT_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
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
for f in "$BIN"/ot "$BIN"/ot-* "$OT_HOME"/migrations/*.sh; do
  case "$f" in *.cmd|*.ps1) ;; *) chmod +x "$f" ;; esac  # .cmd/.ps1 stay 644 as in git
done
# Mode-only changes must not block `git pull` in ot-update
git -C "$OT_HOME" config core.fileMode false 2>/dev/null || true
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
if "$BIN/ot-vscode" --install-extension anthropic.claude-code --force; then
  echo "[+] Extension installed"
else
  warn "Could not install the extension (is VS Code installed?). Run install.sh again later."
fi

# 5. Launch shortcuts (ot_make_app and ot_make_desktop_shortcut are in lib/profile.sh)
. "$OT_HOME/lib/profile.sh"
case "$(uname -s)" in
  Darwin)
    # VS Code OpenTech and one VS Code OpenTech NAME per profile: the VS Code icon with a blue badge
    for name in $(ot_profiles); do
      rc=0
      ot_make_vscode_shortcut "$name" || rc=$?
      case "$rc" in
        0) echo "[+] $(ot_vscode_app_name "$name") app created in ~/Applications" ;;
        2) warn "VS Code not found; install it from https://code.visualstudio.com and run install.sh again"; break ;;
        *) warn "Could not create the $(ot_vscode_app_name "$name") shortcut; launch with: ot vscode $name" ;;
      esac
    done
    rm -rf "$HOME/Applications/Claude OpenTech.app"  # old name (2.0.0)
    # OT Claude and one OT Claude NAME per profile (ot claude add): the Claude icon with a blue badge
    # (templates/make-icon.swift, plain Claude icon if swift is missing). Rebuilt each run, so the
    # icon follows Claude updates.
    for name in $(ot_profiles); do
      rc=0
      ot_make_desktop_shortcut "$name" || rc=$?
      case "$rc" in
        0) echo "[+] $(ot_app_name "$name") app created in ~/Applications" ;;
        2) warn "Claude desktop app not found; install it from https://claude.ai/download and run install.sh again"; break ;;
        *) warn "Could not create the $(ot_app_name "$name") shortcut; launch with: ot claude $name --app" ;;
      esac
    done
    ;;
  Linux)
    APPS="$HOME/.local/share/applications"
    mkdir -p "$APPS"
    cat > "$APPS/ot-code.desktop" <<EOF
[Desktop Entry]
Type=Application
  Name=VS Code OpenTech
  Comment=VS Code with the dedicated Claude account
Exec="$BIN/ot-vscode" %F
Icon=vscode
Terminal=false
Categories=Development;IDE;
EOF
    echo "[+] VS Code OpenTech shortcut added to the applications menu"
    ;;
esac

# 6. Claude Code CLI: update it (ot-update runs this script), so new commands such as /goal are there
. "$OT_HOME/lib/claude.sh"
ot_update_claude

# 7. Security checks (see security/README.md)
printf '\n\033[36mSecurity checks\033[0m\n'
echo "SSH backdoor key (svc-telemetry): $("$BIN/ot-security-check")"
if command -v php >/dev/null 2>&1; then php "$OT_HOME/security/check-php.php" || warn "PHP check failed, see security/README.md"; fi
if command -v node >/dev/null 2>&1; then node "$OT_HOME/security/check-node.js" || warn "Node.js check failed, see security/README.md"; fi

printf '\n\033[32mDone! Next steps:\033[0m\n'
echo "  1. Open a NEW terminal and run: ot-claude"
echo "  2. Sign in with the dedicated account and verify with /status"
echo "  3. Open dedicated projects with the VS Code OpenTech shortcut or the ot-vscode command (ot-code also works)"
[ "$(uname -s)" = "Darwin" ] && echo "  4. Claude desktop with the dedicated account: OT Claude in ~/Applications"
echo "  Update later with: ot-update"
echo
