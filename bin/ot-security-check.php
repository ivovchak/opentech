#!/usr/bin/env php
<?php
// Check for the svc-telemetry SSH key planted by the compromised Claude Code extension in the Cursor marketplace
// Details and cleanup scripts: https://cursor.com/blog/claude-code-extension-security-notice

$home = getenv('HOME') ?: getenv('USERPROFILE');
$files = [$home . DIRECTORY_SEPARATOR . '.ssh' . DIRECTORY_SEPARATOR . 'authorized_keys'];
if (PHP_OS_FAMILY === 'Windows') {
    $files[] = (getenv('ProgramData') ?: 'C:\\ProgramData') . '\\ssh\\administrators_authorized_keys';
}

$found = false;
foreach ($files as $f) {
    $content = @file_get_contents($f);
    if ($content !== false && strpos($content, 'svc-telemetry') !== false) {
        $found = true;
        break;
    }
}
echo $found ? "FOUND\n" : "clean\n";
