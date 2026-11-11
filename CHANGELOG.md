# Changelog

The version is in `VERSION`. Update with `ot-update` (or `git pull` and run the install script again).

One-time changes to existing data are done by migrations in `migrations/`. The install script runs each
new migration once, in order, and records it in `profiles/.migrations`. Every migration has a `.sh`
(macOS / Linux) and a `.ps1` (Windows) version with the same name.

## 2.0.2

- `install.sh` no longer marks `.cmd` files as executable, and sets `core.fileMode false`, so
  `ot-update` (`git pull`) is not blocked by mode-only changes.

## 2.0.1

- The Claude desktop app with the dedicated account is now called **OT Claude** (was Claude OpenTech in 2.0.0). The install script removes the old shortcut.

## 2.0.0

- **Claude desktop with the dedicated account**: `Claude OpenTech` app (macOS: `~/Applications`,
  Windows: desktop shortcut) and the `ot-claude-desktop` command. It runs alongside your personal Claude
  and keeps its data in `profiles/claude-desktop`.
- All logins and settings are now in `profiles/`:
  `claude/` → `profiles/claude-code/`, `claude-api/` → `profiles/claude-code-api/`,
  `vscode/` → `profiles/vscode/`. Migration `0001-profiles` moves them, fixes paths in settings,
  and on macOS copies the `ot-claude` login in the Keychain, so you do not need to sign in again.
- `ot-update` command; versions and migrations.

## 1.x

- `ot-claude`, `ot-claude-api`, `ot-code`, security checks.
