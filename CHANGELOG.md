# Changelog

The version is in `VERSION`. Update with `ot-update` (or `git pull` and run the install script again).

One-time changes to existing data are done by migrations in `migrations/`. The install script runs each
new migration once, in order, and records it in `profiles/.migrations`. Every migration has a `.sh`
(macOS / Linux) and a `.ps1` (Windows) version with the same name.

## 2.3.0

> **Updating from 2.0.x: run this once.** The project history on GitHub was rewritten (the files are
> the same, the commit ids changed), so the old `ot-update` stops with *Not possible to fast-forward*.
> Close `ot-code`, `ot-claude` and OT Claude, then run, once:
>
> - macOS / Linux: `cd ~/.opentech && git fetch && git reset --hard origin/main && ot-update`
> - Windows (PowerShell): `cd $HOME\.opentech; git fetch; git reset --hard origin/main; bin\ot-update.cmd`
>
> Logins and settings in `profiles/` and the `anthropic-api-key` file are git-ignored and are kept;
> only edits you made to the project's own files are discarded. From 2.3.0 on, `ot-update` does this
> step by itself when it is safe.

- **Profiles**: more than one dedicated account side by side. `ot claude add NAME` creates
  `profiles/claude-code-NAME` and `profiles/claude-desktop-NAME` plus an **OT Claude NAME** shortcut
  (macOS: `~/Applications`, with the profile name on the icon badge; Windows: desktop).
  `ot claude list` shows every profile, its account and whether its desktop copy is running;
  `ot claude NAME` starts Claude Code with it and `ot claude NAME --app` the Claude desktop app;
  `ot claude rm NAME` deletes it with its login (macOS: also the Keychain entry).
- The existing folders are the `default` profile; `ot-claude` and `ot-claude-desktop` keep working
  and are now short for `ot claude default` and `ot claude default --app`. No migration.
- The status line badge shows the profile name (`OpenTech NAME`).
- The shortcut badge keeps a trailing number (`client1` → `CLIE1`, `client2` → `CLIE2`).
- Claude desktop is also found outside `/Applications` and `~/Applications` (Spotlight), or set
  `OT_CLAUDE_APP=/path/to/Claude.app`.
- **VS Code per profile**: `ot vscode NAME` opens VS Code with that profile's Claude login and its own
  settings and extensions (`profiles/vscode-NAME`, made on the first start, which also installs the
  Claude extension). macOS: a **VS Code OpenTech NAME** shortcut with the name on the icon badge.
- `ot-vscode` is the new name of `ot-code` (VS Code OpenTech); `ot-code` still works and passes
  everything on to it.
- Fixed: a profile showed as signed out (and asked to sign in again) when `ot` was started through a
  symlink to `~/.opentech`; the scripts now use the real folder path. If `~/.opentech` itself is a
  symlink, sign in once more after updating.
- `ot-update` handles a rewritten history on GitHub: when nothing local would be lost, it moves to
  the new history instead of stopping.
- Fixed: starting OT Claude no longer mistakes a running copy of another profile for itself.
- The **OT Claude** shortcut (macOS) has its own icon: the Claude icon with a blue `OT` badge,
  made at install time by `templates/make-icon.swift`. Without `swift` it keeps the plain Claude icon.
- `ot-update` (and the install script) now also updates Claude Code itself, so new commands such as
  `/goal` are there. If an old Homebrew `claude-code` cask is also installed, it says so and how to remove it.
- `ot-claude` and `ot-claude-api` always run the native Claude Code (`~/.local/bin/claude`) when it is
  installed, even in shells where an old Homebrew copy comes first in PATH.

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
