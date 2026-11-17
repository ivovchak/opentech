# Shared by bin/ot, bin/ot-claude, bin/ot-claude-desktop and install.sh: named Claude profiles.
# Source it with OT_HOME set; do not run it.
#
# A profile is a set of folders in profiles/:
#   default -> claude-code/         (Claude Code: ot-claude, the Code tab)  + claude-desktop/         (OT Claude)
#   <name>  -> claude-code-<name>/                                           + claude-desktop-<name>/  (OT Claude <name>)
# plus vscode/ or vscode-<name>/, made on the first `ot vscode`.
# claude-code-api/ belongs to ot-claude-api and is not a profile.

# Names that would clash with subcommands or with claude-code-api
OT_RESERVED_NAMES="default api list ls add rm remove help desktop"

ot_code_dir() {
  if [ "$1" = default ]; then echo "$OT_HOME/profiles/claude-code"; else echo "$OT_HOME/profiles/claude-code-$1"; fi
}
ot_desktop_dir() {
  if [ "$1" = default ]; then echo "$OT_HOME/profiles/claude-desktop"; else echo "$OT_HOME/profiles/claude-desktop-$1"; fi
}

# ot_valid_name NAME: lowercase letters, digits and dashes, starts with a letter or digit, at most 24 characters
ot_valid_name() {
  case "$1" in ""|-*|*[!a-z0-9-]*) return 1 ;; esac
  [ "${#1}" -le 24 ]
}
ot_reserved_name() {
  case " $OT_RESERVED_NAMES " in *" $1 "*) return 0 ;; esac
  return 1
}

# ot_profiles: print every profile name, default first
ot_profiles() {
  local d n
  echo default
  for d in "$OT_HOME"/profiles/claude-code-*; do
    [ -d "$d" ] || continue
    n="${d##*/claude-code-}"
    ot_reserved_name "$n" && continue
    ot_valid_name "$n" || continue
    echo "$n"
  done
}
ot_profile_exists() {
  [ "$1" = default ] && return 0
  ot_valid_name "$1" && ! ot_reserved_name "$1" && [ -d "$(ot_code_dir "$1")" ]
}

# ot_keychain_service DIR: Claude Code keeps the OAuth login (macOS Keychain) under
# "Claude Code-credentials-<first 8 hex of sha256(config dir)>"
ot_keychain_service() {
  printf 'Claude Code-credentials-%s' "$(printf '%s' "$1" | shasum -a 256 | cut -c1-8)"
}

# ot_account DIR: the signed-in account email of a Claude Code config folder, or nothing
ot_account() {
  [ -f "$1/.claude.json" ] || return 0
  sed -n 's/.*"emailAddress": *"\([^"]*\)".*/\1/p' "$1/.claude.json" | head -1
}

# ot_find_claude_app: print the Claude desktop app bundle (macOS)
ot_find_claude_app() {
  local a
  for a in "${OT_CLAUDE_APP:-}" "/Applications/Claude.app" "$HOME/Applications/Claude.app"; do
    [ -n "$a" ] || continue
    if [ -x "$a/Contents/MacOS/Claude" ]; then echo "$a"; return 0; fi
  done
  # Installed somewhere else: ask Spotlight by bundle id
  if command -v mdfind >/dev/null 2>&1; then
    a="$(mdfind 'kMDItemCFBundleIdentifier == "com.anthropic.claudefordesktop"' 2>/dev/null | head -1)"
    if [ -n "$a" ] && [ -x "$a/Contents/MacOS/Claude" ]; then echo "$a"; return 0; fi
  fi
  return 1
}

# ot_desktop_pid DATA: pid of the Claude desktop copy started on that data folder.
# Matched exactly, so claude-desktop does not also match claude-desktop-<name>. The pattern goes through
# the environment, not `awk -v`, or awk's own command line in `ps` would match it.
ot_desktop_pid() {
  ps -axo pid=,args= 2>/dev/null | OT_PS_PATTERN="MacOS/Claude --user-data-dir=$1" awk '
    BEGIN { d = ENVIRON["OT_PS_PATTERN"] }
    { i = index($0, d)
      if (i && pid == "") { c = substr($0, i + length(d), 1); if (c == "" || c == " ") pid = $1 } }
    END { if (pid != "") print pid }'
  # awk reads all of ps (no early exit): otherwise ps can die of SIGPIPE and, under pipefail, end the caller
}

# ot_app_name NAME: the macOS shortcut name of a profile
ot_app_name() {
  if [ "$1" = default ]; then echo "OT Claude"; else echo "OT Claude $1"; fi
}

# ot_make_app NAME BIN ARGS [ICON]: a small ~/Applications/NAME.app that runs BIN ARGS in the background
ot_make_app() {
  local app="$HOME/Applications/$1.app"
  mkdir -p "$HOME/Applications"
  rm -rf "$app"
  osacompile -o "$app" -e "do shell script quoted form of \"$2\" & \" $3 > /dev/null 2>&1 &\"" 2>/dev/null || return 1
  if [ -n "${4:-}" ] && [ -f "$4" ]; then
    cp "$4" "$app/Contents/Resources/applet.icns"
    codesign --force --sign - "$app" >/dev/null 2>&1 || true
    touch "$app"
  fi
}

# ot_badge_label NAME: up to 5 characters for the icon badge. A trailing number is kept, so client1
# and client2 stay apart (CLIE1, CLIE2); dashes are dropped.
ot_badge_label() {
  local n digits head
  if [ "$1" = default ]; then echo OT; return; fi
  n="$(printf '%s' "$1" | tr -d '-' | tr '[:lower:]' '[:upper:]')"
  if [ "${#n}" -le 5 ]; then echo "$n"; return; fi
  digits="$(printf '%s' "$n" | sed -n 's/.*[^0-9]\([0-9]\{1,3\}\)$/\1/p')"
  head="$(printf '%s' "${n%"$digits"}" | cut -c1-$((5 - ${#digits})))"
  echo "$head$digits"
}

# ot_make_badged_app APP ICON LABEL BIN ARGS: ot_make_app with ICON plus a blue LABEL badge
# (templates/make-icon.swift; the plain ICON if swift is missing)
ot_make_badged_app() {
  local icon="$2" t rc=0
  t="$(mktemp -d)"
  if command -v swift >/dev/null 2>&1 &&
     swift "$OT_HOME/templates/make-icon.swift" "$icon" "$t/ot.icns" "$3" >/dev/null 2>&1; then
    icon="$t/ot.icns"
  fi
  ot_make_app "$1" "$4" "$5" "$icon" || rc=1
  rm -rf "$t"
  return "$rc"
}

# ot_make_desktop_shortcut NAME: ~/Applications/OT Claude[ NAME].app, with the Claude icon and a blue
# badge (OT, or the profile name). macOS only; returns 2 when the Claude desktop app is missing.
ot_make_desktop_shortcut() {
  local name="$1" claude
  [ "$(uname -s)" = Darwin ] || return 0
  claude="$(ot_find_claude_app)" || return 2
  if [ "$name" = default ]; then
    set -- "$OT_HOME/bin/ot-claude-desktop" ""
  else
    set -- "$OT_HOME/bin/ot" "claude $name --app"
  fi
  ot_make_badged_app "$(ot_app_name "$name")" "$claude/Contents/Resources/electron.icns" \
    "$(ot_badge_label "$name")" "$1" "$2"
}

# --- VS Code: one instance per profile, with that profile's Claude Code login -------------------
#   default -> profiles/vscode/         (ot-vscode, ot-code, VS Code OpenTech)
#   <name>  -> profiles/vscode-<name>/  (ot vscode <name>, VS Code OpenTech <name>)
# Each has data/ (settings, state) and extensions/ (its own Claude Code extension).

ot_vscode_dir() {
  if [ "$1" = default ]; then echo "$OT_HOME/profiles/vscode"; else echo "$OT_HOME/profiles/vscode-$1"; fi
}
ot_vscode_app_name() {
  if [ "$1" = default ]; then echo "VS Code OpenTech"; else echo "VS Code OpenTech $1"; fi
}

# ot_find_vscode_app: print the VS Code app bundle (macOS)
ot_find_vscode_app() {
  local a
  for a in "/Applications/Visual Studio Code.app" "$HOME/Applications/Visual Studio Code.app"; do
    if [ -x "$a/Contents/Resources/app/bin/code" ]; then echo "$a"; return 0; fi
  done
  if command -v mdfind >/dev/null 2>&1; then
    a="$(mdfind 'kMDItemCFBundleIdentifier == "com.microsoft.VSCode"' 2>/dev/null | head -1)"
    if [ -n "$a" ] && [ -x "$a/Contents/Resources/app/bin/code" ]; then echo "$a"; return 0; fi
  fi
  return 1
}

# ot_find_code: print the VS Code command line launcher
ot_find_code() {
  local a
  if a="$(ot_find_vscode_app)"; then echo "$a/Contents/Resources/app/bin/code"; return 0; fi
  command -v code
}

# ot_vscode_init NAME: create the profile's VS Code folders and settings.json (Claude Code login of
# the profile in its terminals, blue title and status bar, "[OpenTech NAME]" in the window title)
ot_vscode_init() {
  local dir settings title=OpenTech
  dir="$(ot_vscode_dir "$1")"
  settings="$dir/data/User/settings.json"
  mkdir -p "$dir/data/User" "$dir/extensions"
  chmod 700 "$dir"
  [ -f "$settings" ] && return 0
  [ "$1" = default ] || title="OpenTech $1"
  sed -e "s|__CLAUDE_CONFIG_DIR__|$(ot_code_dir "$1")|g" -e "s|\[OpenTech\]|[$title]|" \
    "$OT_HOME/templates/settings.json" > "$settings"
  echo "[+] Created VS Code settings for profile $1"
}

# ot_vscode_has_claude NAME: the Claude Code extension is installed in that profile's VS Code
ot_vscode_has_claude() {
  local e
  for e in "$(ot_vscode_dir "$1")"/extensions/anthropic.claude-code-*; do [ -d "$e" ] && return 0; done
  return 1
}

# ot_make_vscode_shortcut NAME: ~/Applications/VS Code OpenTech[ NAME].app with the VS Code icon and a
# blue badge. macOS only; returns 2 when VS Code is missing.
ot_make_vscode_shortcut() {
  local name="$1" app
  [ "$(uname -s)" = Darwin ] || return 0
  app="$(ot_find_vscode_app)" || return 2
  if [ "$name" = default ]; then
    set -- "$OT_HOME/bin/ot-vscode" ""
  else
    set -- "$OT_HOME/bin/ot" "vscode $name"
  fi
  ot_make_badged_app "$(ot_vscode_app_name "$name")" "$app/Contents/Resources/Code.icns" \
    "$(ot_badge_label "$name")" "$1" "$2"
}
