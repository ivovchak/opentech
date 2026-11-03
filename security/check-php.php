<?php
// Check the PHP version against the critical RCE fix of 21 Oct 2026 (CVE-2026-109618, CVE-2026-109619)
// Advisory: https://www.php.net/archive/2026.php#2026-10-21-5
//
// Usage: php check-php.php [version]
//   without an argument, checks the PHP that runs the script;
//   with an argument (for example from `php-fpm8.3 -v`), checks that version string.
// Exit code: 0 = PASS (warnings allowed), 1 = FAIL

const ADVISORY = 'https://www.php.net/archive/2026.php#2026-10-21-5';

// Minimal fixed release per supported branch
const FIXED = [
    '8.2' => '8.2.35',
    '8.3' => '8.3.36',
    '8.4' => '8.4.27',
    '8.5' => '8.5.12',
    '8.6' => '8.6.0RC4',
];

$version = $argv[1] ?? PHP_VERSION;
$self = !isset($argv[1]);
if (!preg_match('/^(\d+)\.(\d+)\.\d+/', $version, $m)) {
    fwrite(STDERR, "Cannot parse PHP version: $version\n");
    exit(1);
}
$branch = "$m[1].$m[2]";

$fail = [];
$warn = [];

if (isset(FIXED[$branch])) {
    if (version_compare($version, FIXED[$branch], '<')) {
        $fail[] = "PHP $version is vulnerable to CVE-2026-109618 and CVE-2026-109619 (unauthenticated RCE, CVSS 9.2). Update to " . FIXED[$branch] . ' or later.';
    }
} elseif (version_compare($branch, '8.2', '<')) {
    $fail[] = "PHP $version is end-of-life and has no official fix for CVE-2026-109618 and CVE-2026-109619. Upgrade to a supported version, or confirm a backported fix with your distribution or LTS vendor.";
} else {
    $warn[] = "PHP $branch is newer than this check knows about; confirm it includes the fixes from " . ADVISORY;
}

if ($self) {
    // CVE-2026-115560 (informational advisory of 23 Oct 2026): unlikely RCE vector through session upload progress
    if (filter_var(ini_get('session.upload_progress.enabled'), FILTER_VALIDATE_BOOLEAN)) {
        $warn[] = 'session.upload_progress.enabled=1; php.net suggests 0 until the next bugfix release (CVE-2026-115560). Not needed if the app never changes session.serialize_handler at runtime.';
    }

    // CVE-2026-111497: Brotli in PHP Windows builds, fixed by the -1 rebuilds of 26 Oct 2026
    if (PHP_OS_FAMILY === 'Windows' && function_exists('curl_version')) {
        $curl = curl_version();
        if (isset($curl['brotli_version']) && preg_match('/(\d+\.\d+\.\d+)/', $curl['brotli_version'], $b)
            && version_compare($b[1], '1.2.1', '<')) {
            $warn[] = "Windows build bundles Brotli $b[1] (CVE-2026-111497). Install the -1 rebuild of 26 Oct 2026 with Brotli 1.2.1.";
        }
    }
}

echo "PHP $version" . ($self ? ' (' . PHP_SAPI . ', ' . PHP_BINARY . ')' : '') . "\n";
foreach ($fail as $msg) {
    echo "  [FAIL] $msg\n";
}
foreach ($warn as $msg) {
    echo "  [WARN] $msg\n";
}
if ($fail) {
    echo "Result: FAIL - see " . ADVISORY . "\n";
    exit(1);
}
echo "Result: PASS\n";
exit(0);
