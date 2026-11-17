# Shared by bin/ot-claude, bin/ot-claude-api and install.sh: find and update the Claude Code CLI.
# Source it; do not run it.

# ot_claude_bin: print the claude to run.
# The native install (~/.local/bin/claude, kept current by `claude update`) wins over whatever comes
# first in PATH, for example an old Homebrew cask that lacks newer commands such as /goal.
ot_claude_bin() {
  local c
  for c in "$HOME/.local/bin/claude" "$HOME/.claude/local/claude"; do
    if [ -x "$c" ]; then echo "$c"; return 0; fi
  done
  command -v claude
}

# ot_update_claude: update the CLI that ot-claude runs, and warn about an old Homebrew copy that
# other shells may still pick up first in PATH.
ot_update_claude() {
  local bin real brew_ver
  if ! bin="$(ot_claude_bin)"; then
    printf '\033[33m[!] %s\033[0m\n' "Claude Code CLI not found. Install it with: curl -fsSL https://claude.ai/install.sh | bash"
    return 0
  fi
  real="$(readlink -f "$bin" 2>/dev/null || echo "$bin")"
  echo "[..] Updating Claude Code ($bin)"
  case "$real" in
    */Caskroom/*) brew upgrade --cask claude-code || true ;;
    *) "$bin" update || true ;;
  esac
  echo "[+] Claude Code $("$bin" --version 2>/dev/null | awk '{print $1}')"

  if command -v brew >/dev/null 2>&1 && brew list --cask claude-code >/dev/null 2>&1; then
    case "$real" in
      */Caskroom/*) ;;
      *)
        brew_ver="$(brew list --cask --versions claude-code 2>/dev/null | awk '{print $2}')"
        printf '\033[33m[!] %s\033[0m\n' "An old Homebrew Claude Code ($brew_ver) is also installed and may start in shells where it comes first in PATH. Remove it with: brew uninstall --cask claude-code"
        ;;
    esac
  fi
}
