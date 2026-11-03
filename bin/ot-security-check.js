#!/usr/bin/env node
// Check for the svc-telemetry SSH key planted by the compromised Claude Code extension in the Cursor marketplace
// Details and cleanup scripts: https://cursor.com/blog/claude-code-extension-security-notice
const fs = require('fs');
const os = require('os');
const path = require('path');

const files = [path.join(os.homedir(), '.ssh', 'authorized_keys')];
if (process.platform === 'win32') {
  files.push(path.join(process.env.ProgramData || 'C:\\ProgramData', 'ssh', 'administrators_authorized_keys'));
}

const found = files.some((f) => {
  try { return fs.readFileSync(f, 'utf8').includes('svc-telemetry'); } catch { return false; }
});
console.log(found ? 'FOUND' : 'clean');
