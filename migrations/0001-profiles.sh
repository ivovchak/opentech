#!/usr/bin/env bash
# 0001: move claude/, claude-api/ and vscode/ into profiles/
#   claude/     -> profiles/claude-code/
#   claude-api/ -> profiles/claude-code-api/
#   vscode/     -> profiles/vscode/
# Also fixes absolute paths in JSON files and, on macOS, copies the Keychain login
# (Claude Code names it after a hash of the config folder path).
set -euo pipefail

OT_HOME="$1"
P="$OT_HOME/profiles"
mkdir -p "$P"

# old name -> new name
pairs="claude:claude-code claude-api:claude-code-api vscode:vscode"

# Refuse to move folders that are in use
if pgrep -f "user-data-dir $OT_HOME/vscode" >/dev/null 2>&1; then
  echo "VS Code OpenTech (ot-code) is running. Close it and run install.sh again." >&2
  exit 1
fi

moved=""
for pair in $pairs; do
  old="${pair%%:*}"; new="${pair##*:}"
  [ -d "$OT_HOME/$old" ] || continue
  if [ -e "$P/$new" ] && [ -n "$(ls -A "$P/$new" 2>/dev/null)" ]; then
    echo "Both $OT_HOME/$old and $P/$new exist; merge them manually and run install.sh again." >&2
    exit 1
  fi
  rmdir "$P/$new" 2>/dev/null || true
  mv "$OT_HOME/$old" "$P/$new"
  echo "    moved $old/ -> profiles/$new/"
  moved="$moved $old:$new"
done
[ -n "$moved" ] || exit 0

# Fix absolute paths in JSON files (VS Code settings, extension list, plugin marketplaces).
# claude-api is replaced before claude because one is a prefix of the other.
fix_paths() {
  OT="$OT_HOME" perl -0pi -e '
    my $ot = quotemeta $ENV{OT};
    s{$ot/claude-api(?=[/"\\]|$)}{$ENV{OT}/profiles/claude-code-api}g;
    s{$ot/claude(?=[/"\\]|$)}{$ENV{OT}/profiles/claude-code}g;
    s{$ot/vscode(?=[/"\\]|$)}{$ENV{OT}/profiles/vscode}g;
  ' "$1"
}
{ find "$P" -type f -name '*.json' \
    -not -path '*/projects/*' -not -path '*/Cache*' -not -path '*/node_modules/*' \
    -exec grep -lF "$OT_HOME/" {} + 2>/dev/null || true; } | while IFS= read -r f; do
    fix_paths "$f"
    echo "    fixed paths in ${f#"$OT_HOME"/}"
  done

# macOS: Claude Code keeps the OAuth login in the Keychain under
# "Claude Code-credentials-<first 8 hex of sha256(config dir)>". Copy it to the new name.
if [ "$(uname -s)" = "Darwin" ] && command -v security >/dev/null 2>&1; then
  for pair in $moved; do
    old="${pair%%:*}"; new="${pair##*:}"
    [ "$old" = "vscode" ] && continue
    h_old="$(printf '%s' "$OT_HOME/$old" | shasum -a 256 | cut -c1-8)"
    h_new="$(printf '%s' "$P/$new" | shasum -a 256 | cut -c1-8)"
    if secret="$(security find-generic-password -a "$USER" -s "Claude Code-credentials-$h_old" -w 2>/dev/null)"; then
      security add-generic-password -U -a "$USER" -s "Claude Code-credentials-$h_new" -w "$secret"
      echo "    copied the $old login in the Keychain"
    fi
  done
fi
