# Isolated Claude Code, Claude desktop and VS Code profile

This repository configures a separate Claude account so it does not mix with your personal account.

- `ot-claude` — Claude Code using the dedicated account (the regular `claude` command remains personal)
- **Claude OpenTech** (`ot-claude-desktop`) — a second Claude desktop app with the dedicated account, running alongside your personal Claude (macOS and Windows)
- `ot-code` — a separate VS Code instance with its own settings, extensions, and login (your regular VS Code is unaffected)

All dedicated logins and settings are stored in `~/.opentech/profiles/`; your personal ones stay in the standard places (`~/.claude`, the regular Claude app and VS Code).

| Folder | Used by |
| --- | --- |
| `profiles/claude-code/` | `ot-claude`, `ot-code`, and the Code tab of Claude OpenTech |
| `profiles/claude-code-api/` | `ot-claude-api` |
| `profiles/claude-desktop/` | Claude OpenTech (chats, desktop app settings) |
| `profiles/vscode/` | `ot-code` (settings and extensions) |

## Requirements

- [Git](https://git-scm.com)
- [VS Code](https://code.visualstudio.com)
- [Claude Code](https://docs.claude.com/en/docs/claude-code/overview)
- [Claude desktop](https://claude.ai/download) (optional, for Claude OpenTech; on Windows the Microsoft Store version is not supported)
- A separate Claude account

## Installation

### Windows

```powershell
git clone https://github.com/ivovchak/opentech.git "$HOME\.opentech"
& "$HOME\.opentech\install.cmd"
```

Or open the `C:\Users\<username>\.opentech` folder and double-click `install.cmd`.

### macOS / Linux

```bash
git clone https://github.com/ivovchak/opentech.git ~/.opentech
bash ~/.opentech/install.sh
```

The installation script:

1. applies new [migrations](#versions-and-migrations) to existing data;
2. creates the `profiles/` directories;
3. adds `~/.opentech/bin` to PATH (the `ot-claude`, `ot-code`, `ot-claude-desktop` and `ot-update` commands);
4. creates dedicated VS Code settings (a blue title bar and status bar, with `[OpenTech]` in the window title);
5. installs the Claude Code extension in the dedicated VS Code instance;
6. creates **VS Code OpenTech** and **Claude OpenTech** shortcuts (Windows: desktop, macOS: `~/Applications`, Linux: applications menu, VS Code only).

You can run the script again; it does not overwrite existing settings.

## First login

1. Open a **new** terminal.
2. Run `ot-claude` and sign in with the dedicated account.
   If the browser selects your personal account, sign out of claude.ai or use a private window.
3. Check `/status`; it should show the dedicated account email and subscription.
4. Run the regular `claude` command, then `/status`; it should still show your personal account.

## Daily use

| What | How |
| --- | --- |
| Dedicated projects | the **VS Code OpenTech** shortcut or `ot-code <folder>` |
| Dedicated Claude in the terminal | `ot-claude` |
| Dedicated Claude desktop app | the **Claude OpenTech** shortcut or `ot-claude-desktop` |
| Claude billed to the API key | `ot-claude-api` |
| Personal projects | regular VS Code and `claude` |

Open dedicated projects **only** through `ot-code`; the regular VS Code shortcut uses your personal account.

## Claude desktop (Claude OpenTech)

Claude OpenTech is the same Claude app you already have, started with its own data folder (`profiles/claude-desktop`). It does not change your personal Claude app, and both can be open at the same time.

- Sign in on first launch with the dedicated account. Use the **email code** login: after browser login (for example Google), the `claude://` link may open your personal Claude instead.
- Its Code tab uses `profiles/claude-code`, the same login and settings as `ot-claude`.
- In the Dock and the taskbar both copies have the same Claude icon; check the account in the app settings.
- Clicking the shortcut again brings the running Claude OpenTech to the front instead of starting a second copy (two copies on one data folder could damage it).
- It relies on Claude's `--user-data-dir` start option, which is not officially documented. If a Claude update stops supporting it, Claude OpenTech will open with your personal data; tell the maintainer.

## API key mode

`ot-claude-api` runs Claude Code billed to an Anthropic API key (pay per token) instead of the subscription. It uses its own config directory, `~/.opentech/profiles/claude-code-api`, so it never mixes with the subscription login.

Create a key in the [Claude Console](https://console.anthropic.com) and save it locally:

```bash
printf '%s' 'sk-ant-...' > ~/.opentech/anthropic-api-key && chmod 600 ~/.opentech/anthropic-api-key
```

```powershell
Set-Content -NoNewline "$HOME\.opentech\anthropic-api-key" 'sk-ant-...'
```

Alternatively, set `OT_ANTHROPIC_API_KEY` for the current shell. Run `/status` in the session to confirm that it uses the API key, and set a spend limit in the Console.

`anthropic-api-key` and `profiles/` are listed in `.gitignore`; **never commit them**. If the key leaks, revoke it in the Console immediately.

`ot-claude` always uses the subscription, even if `ANTHROPIC_API_KEY` is set globally.

### Example: unattended automation

The interactive `ot-claude-api` session waits for your answers and permission prompts. For automation, run it in headless mode (`-p`): it completes the task and exits without asking anything.

```bash
ot-claude-api -p "Process every file in docs/ according to PLAN.md and save the results to out/" \
  --max-turns 50 \
  --allowedTools "Read,Write,Edit,Glob,Grep" \
  --output-format json > run.log
```

- `-p` runs non-interactively and exits when done;
- `--allowedTools` allows only the listed tools; without it, the run stops at the first permission prompt;
- `--max-turns` caps the number of agent steps so a run cannot loop forever;
- `run.log` contains the result and the cost of the run.

Things to keep in mind:

- **No subscription time limits**, but you pay per token; set a spend limit in the Console.
- **API rate limits** depend on your account tier; a new account has low limits, so large runs may slow down or hit `429` errors. See [Rate limits](https://platform.claude.com/docs/en/api/rate-limits).
- **The computer must stay awake** for the whole run.
- **Test on 2-3 files first** and check the cost in `run.log` before processing everything.
- For hundreds of documents where results are not needed immediately, a script using the [Batch API](https://platform.claude.com/docs/en/build-with-claude/batch-processing) (50% discount) is cheaper than an agent session.

More details: [Run Claude Code programmatically](https://code.claude.com/docs/en/headless), [Permission modes](https://code.claude.com/docs/en/permission-modes), [Pricing](https://platform.claude.com/docs/en/about-claude/pricing).

## Updates

```bash
ot-update
```

It pulls the latest version and runs the install script again, which applies new migrations. Versions before 2.0.0 do not have `ot-update` yet; update them once with `cd ~/.opentech && git pull && bash install.sh` (Windows: `git pull`, then `install.cmd`). Close `ot-code`, `ot-claude` and Claude OpenTech first. Your logins and settings in `profiles/` are kept.

## Versions and migrations

The current version is in `VERSION`; changes are listed in [CHANGELOG.md](CHANGELOG.md).

When a new version needs to change existing data (for example, move a folder), it ships a migration in `migrations/`: `NNNN-name.sh` for macOS / Linux and `NNNN-name.ps1` for Windows. The install script runs every migration that is not yet listed in `profiles/.migrations`, in order, and records it after it succeeds. If a migration fails, the install stops; fix the problem it reports and run the install script again.

Version 2.0.0 includes migration `0001-profiles`, which moves the old `claude/`, `claude-api/` and `vscode/` folders into `profiles/`, fixes paths in their settings, and on macOS copies the `ot-claude` login in the Keychain, so you do not need to sign in again.

To add a migration: create both files with the next number, make them safe to run on a fresh install (nothing to migrate) and when interrupted, bump `VERSION` and describe it in `CHANGELOG.md`.

## Security

The `profiles/` directory and the `anthropic-api-key` file contain your tokens and personal settings. They are listed in `.gitignore`; **never commit them** or remove those entries from `.gitignore`.

### Security checks

[security/README.md](security/README.md) describes the known incidents and how to check your machine and servers:

- critical PHP RCE of October 2026 (CVE-2026-109618, CVE-2026-109619): `php ~/.opentech/security/check-php.php`;
- Node.js security release of October 2026, including the Brotli RCE (CVE-2026-111497): `node ~/.opentech/security/check-node.js`;
- backdoored Claude Code extension in the Cursor marketplace: `ot-security-check`.

## Troubleshooting

| Symptom | What to do |
| --- | --- |
| `ot-claude` not found | open a new terminal; on Windows, check that `%USERPROFILE%\.opentech\bin` is in PATH |
| `ot-code` asks for login every time | launch it only through the shortcut or `ot-code`; in the VS Code terminal, `echo $env:CLAUDE_CONFIG_DIR` (Windows) or `echo $CLAUDE_CONFIG_DIR` should show `.opentech/profiles/claude-code` |
| Both VS Code instances use the same account | make sure `CLAUDE_CONFIG_DIR` is not set globally on the system |
| Claude OpenTech shows your personal chats | open it only through the shortcut or `ot-claude-desktop`; the regular Claude icon starts your personal copy |
| Install stops at a migration | read the message above it (often a running `ot-code`), fix it, and run the install script again |
| Unwanted global instructions in context | do not keep instructions in `~/.claude/CLAUDE.md`; put `CLAUDE.md` in the project root |

## Uninstallation

Close `ot-code`, `ot-claude` and Claude OpenTech first.

### Windows

```powershell
& "$HOME\.opentech\uninstall.cmd"
```

Or double-click `uninstall.cmd` in the `.opentech` folder.

### macOS / Linux

```bash
bash ~/.opentech/uninstall.sh
```

The uninstallation script removes `~/.opentech/bin` from PATH and the **VS Code OpenTech** and **Claude OpenTech** shortcuts, then asks whether to delete the `.opentech` folder completely, **including the dedicated logins and settings in `profiles/`**. Answer `N` to keep them. To delete without asking, pass `--yes` (macOS / Linux) or run `uninstall.ps1 -Yes` (Windows).

Your personal `claude`, Claude app and regular VS Code are not affected.

> `CLAUDE_CONFIG_DIR` is a stable but officially undocumented Claude Code variable. Use the dedicated subscription only for its intended work.
