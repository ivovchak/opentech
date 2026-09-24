# Separate Claude Code and VS Code

This repository configures a separate Claude Code account so it does not mix with your personal account.

- `ot-claude` — Claude Code using the dedicated account (the regular `claude` command remains personal)
- **VS Code OT** — a separate VS Code instance with its own settings, extensions, and login (your regular VS Code is unaffected)

The dedicated login is stored in `~/.opentech/claude`; the personal login remains in the standard `~/.claude`.

## Requirements

- [Git](https://git-scm.com)
- [VS Code](https://code.visualstudio.com)
- [Claude Code](https://docs.claude.com/en/docs/claude-code/overview)
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

1. creates the `claude/` and `vscode/` directories;
2. adds `~/.opentech/bin` to PATH (the `ot-claude` and `ot-vscode` commands);
3. creates dedicated VS Code settings (a blue title bar and status bar, with `[OT]` in the window title);
4. installs the Claude Code extension in the dedicated VS Code instance;
5. creates a VS Code OT shortcut (Windows: desktop, macOS: `~/Applications`, Linux: applications menu).

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
| Dedicated projects | the VS Code OT shortcut or `ot-vscode <folder>` |
| Dedicated Claude in the terminal | `ot-claude` |
| Personal projects | regular VS Code and `claude` |

Open dedicated projects **only** through VS Code OT; the regular VS Code shortcut uses your personal account.

## Updates

```bash
cd ~/.opentech && git pull
```

Logins and settings (`claude/`, `vscode/`) are not changed.

## Security

The `claude/` and `vscode/` directories contain your tokens and personal settings. They are listed in `.gitignore`; **never commit them** or remove those entries from `.gitignore`.

## Troubleshooting

| Symptom | What to do |
| --- | --- |
| `ot-claude` not found | open a new terminal; on Windows, check that `%USERPROFILE%\.opentech\bin` is in PATH |
| VS Code OT asks for login every time | launch it only through the shortcut or `ot-vscode`; in the VS Code terminal, `echo $env:CLAUDE_CONFIG_DIR` (Windows) or `echo $CLAUDE_CONFIG_DIR` should show `.opentech/claude` |
| Both VS Code instances use the same account | make sure `CLAUDE_CONFIG_DIR` is not set globally on the system |
| Unwanted global instructions in context | do not keep instructions in `~/.claude/CLAUDE.md`; put `CLAUDE.md` in the project root |

## Uninstallation

- Windows: delete `%USERPROFILE%\.opentech`, the desktop shortcut, and the `...\.opentech\bin` entry from the user PATH variable.
- macOS / Linux: delete `~/.opentech`, the line marked `# opentech-bin` from `~/.zshrc` / `~/.bashrc`, and `~/Applications/VS Code OT.app` (macOS) or `~/.local/share/applications/ot-vscode.desktop` (Linux).

> `CLAUDE_CONFIG_DIR` is a stable but officially undocumented Claude Code variable. Use the dedicated subscription only for its intended work.
