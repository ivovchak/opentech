# Security checks

Quick checks for known incidents that affect developer machines and servers. Each check prints a clear result: `clean` / `FOUND` or `PASS` / `FAIL`.

| Check | Severity | Command | Fails when |
| --- | --- | --- | --- |
| [PHP RCE, October 2026](#php-rce-cve-2026-109618-cve-2026-109619) | **Critical** | `php ~/.opentech/security/check-php.php` | PHP is older than the fixed release of its branch |
| [Node.js, October 2026](#nodejs-security-release-october-2026) | **High** (RCE) | `node ~/.opentech/security/check-node.js` | Node.js is older than the fixed release of its line, or the line is end-of-life |
| [Backdoored Claude Code extension in Cursor](#backdoored-claude-code-extension-in-cursor) | **Critical** | `ot-security-check` | the `svc-telemetry` SSH key is present |

Run every check on each machine you use for work, and the PHP and Node.js checks on every server and in every Docker image you deploy.

## PHP RCE (CVE-2026-109618, CVE-2026-109619)

On 21 October 2026, the PHP project released fixes for two critical vulnerabilities (CVSS v4.0 9.2) that allow **unauthenticated remote code execution**:

- CVE-2026-109618: RCE via OOM corruption;
- CVE-2026-109619: RCE via stale global state.

Every PHP installation that serves web requests is at risk: PHP-FPM, Apache mod_php, php-cgi, FrankenPHP and LiteSpeed. The risk is highest for mod_php, where a demonstrated exploit triggers before any application code runs. WordPress, Drupal, Joomla, Magento and any other PHP application are affected through PHP itself; updating the CMS does not help.

### Fixed versions

| Branch | Minimal safe version |
| --- | --- |
| 8.5 | 8.5.12 |
| 8.4 | 8.4.27 |
| 8.3 | 8.3.36 |
| 8.2 | 8.2.35 (end of life on 31 December 2026) |
| 8.6 (pre-release) | 8.6.0 RC4 |
| 8.1 and older | no official fix: upgrade, or get a backport from your distribution or LTS vendor |

### Check

```bash
php ~/.opentech/security/check-php.php
```

```
PHP 8.5.7 (cli, /opt/homebrew/Cellar/php/8.5.7/bin/php)
  [FAIL] PHP 8.5.7 is vulnerable to CVE-2026-109618 and CVE-2026-109619 (unauthenticated RCE, CVSS 9.2). Update to 8.5.12 or later.
Result: FAIL - see https://www.php.net/archive/2026.php#2026-10-21-5
```

The exit code is `0` for `PASS` and `1` for `FAIL`, so the check can run in CI or a monitoring script.

The command checks the PHP CLI. A web server can run a **different** PHP binary (FPM pool, mod_php), so check the version that actually serves requests:

```bash
php ~/.opentech/security/check-php.php "$(php-fpm8.3 -v | head -1 | awk '{print $2}')"
```

Or pass any version string, for example from a hosting control panel or `phpinfo()`:

```bash
php ~/.opentech/security/check-php.php 8.3.30
```

The check also warns (without failing) about:

- `session.upload_progress.enabled=1`: php.net suggests `0` until the next bugfix release (CVE-2026-115560, an unlikely RCE vector when an app changes `session.serialize_handler` at runtime);
- Windows builds that bundle Brotli older than 1.2.1 (CVE-2026-111497): install the `-1` rebuild of 26 October 2026.

### If the check fails

1. **Update PHP** to the version in the table and restart every PHP worker (FPM, Apache). Only an update is a complete fix.
2. If you cannot update right now, reduce exposure as described in the advisory; these measures do **not** make the installation safe:
   - `memory_limit=-1` and a low `post_max_size` (`8M` without uploads, `32M` with uploads), set with `php_admin_value` so applications cannot override them;
   - `session.upload_progress.enabled=0` in `php.ini` or the FPM pool, not via `ini_set()` or `.user.ini`;
   - on PHP 8.5, `fatal_error_backtraces=0`.
3. Check the server for signs of compromise if it was exposed between 21 October and the update.

> **Distribution packages.** Debian, Ubuntu, RHEL and similar distributions often backport fixes without changing the upstream version number (for example, `8.3.6` from Ubuntu can already be patched). If the check fails on a distribution package, confirm the status in your distribution's security tracker for CVE-2026-109618 and CVE-2026-109619 before deciding that the server is safe.

Advisory: <https://www.php.net/archive/2026.php#2026-10-21-5>

## Node.js security release, October 2026

On 21 October 2026, Node.js released fixes for 10 vulnerabilities in the 22.x, 24.x and 26.x lines. The most serious one:

- **CVE-2026-111497** (High): an out-of-bounds write in the Brotli decoder bundled with Node.js. An attacker who can supply Brotli data that the application decompresses with `node:zlib` can crash the process, read process memory, or **execute code**. Any Node.js app that decompresses responses or uploads (for example `fetch()` responses or HTTP middleware) can be exposed.

The other High issues are TLS certificate hostname bypasses (CVE-2026-105483, CVE-2026-106069) and a `dns.resolve` flaw that truncates names at a NUL character (CVE-2026-105482). The release also fixes Medium and Low issues, including CVE-2026-106074: `crypto.randomUUID()` and `randomInt()` values repeat across processes started from a startup snapshot or single executable application.

### Fixed versions

| Line | Minimal safe version |
| --- | --- |
| 26.x | 26.12.1 |
| 24.x | 24.22.1 |
| 22.x | 22.23.4 |
| 25.x, 23.x, 20.x and older | end of life, always affected: upgrade to 22, 24 or 26 |

### Check

```bash
node ~/.opentech/security/check-node.js
```

```
Node.js 22.22.3 (/usr/local/bin/node)
  [FAIL] Node.js 22.22.3 is vulnerable, including CVE-2026-111497 (Brotli decoder out-of-bounds write, possible RCE). Update to 22.23.4 or later.
Result: FAIL - see https://nodejs.org/en/blog/vulnerability/october-2026-security-releases
```

The exit code is `0` for `PASS` and `1` for `FAIL`.

The command checks the `node` that is first in `PATH`. A machine often has several Node.js installations (nvm, Homebrew, tools that bundle their own Node.js), and servers usually run Node.js inside Docker images. Pass the version that actually runs the app:

```bash
node ~/.opentech/security/check-node.js "$(docker run --rm my-app:latest node -v)"
node ~/.opentech/security/check-node.js 24.22.0
```

### If the check fails

1. **Update Node.js** to the version in the table (or the latest release of the line), then rebuild and redeploy Docker images that use it: a base image such as `node:22` only picks up the fix when the image is rebuilt.
2. Restart every running Node.js process.
3. If you build startup snapshots (`--build-snapshot`) or single executable applications, rebuild them with the fixed version (CVE-2026-106074).
4. Until you can update, do not decompress untrusted Brotli data.

Advisory: <https://nodejs.org/en/blog/vulnerability/october-2026-security-releases>

## Backdoored Claude Code extension in Cursor

On 29 October 2026, a tampered `Anthropic.claude-code` 2.1.312 / 2.1.313 was published in the Cursor extension marketplace. It sent machine data to the attacker, added an SSH key labeled `svc-telemetry` to `authorized_keys`, and installed autostart entries. Removing the extension does not remove them.

### Check

| OS | Command |
| --- | --- |
| macOS / Linux | `ot-security-check` |
| Windows | `ot-security-check.cmd` (also checks `C:\ProgramData\ssh\administrators_authorized_keys`) |
| Node.js (any OS) | `node ~/.opentech/bin/ot-security-check.js` |
| PHP (any OS) | `php ~/.opentech/bin/ot-security-check.php` |

`clean` means the key was not found. The check looks only for the SSH key, not for the autostart entries.

### If the check prints `FOUND`

1. Isolate the machine.
2. Run Cursor's cleanup script.
3. From a clean device, rotate the keys, tokens and sessions that were reachable from this machine.
4. Consider reinstalling the system.

Indicators of compromise and cleanup scripts: <https://cursor.com/blog/claude-code-extension-security-notice>
