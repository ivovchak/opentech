#!/usr/bin/env node
// Check the Node.js version against the security release of 21 Oct 2026 (10 CVEs, including the Brotli RCE CVE-2026-111497)
// Advisory: https://nodejs.org/en/blog/vulnerability/october-2026-security-releases
//
// Usage: node check-node.js [version]
//   without an argument, checks the Node.js that runs the script;
//   with an argument (for example from `node -v` on a server or in a Docker image), checks that version string.
// Exit code: 0 = PASS (warnings allowed), 1 = FAIL

const ADVISORY = 'https://nodejs.org/en/blog/vulnerability/october-2026-security-releases';

// Minimal fixed release per supported line
const FIXED = {
  22: '22.23.4',
  24: '24.22.1',
  26: '26.12.1',
};
const LATEST_KNOWN_LINE = 26;

const parse = (v) => v.replace(/^v/, '').split(/[.-]/).slice(0, 3).map(Number);
const lessThan = (a, b) => {
  const [x, y] = [parse(a), parse(b)];
  for (let i = 0; i < 3; i++) if (x[i] !== y[i]) return x[i] < y[i];
  return false;
};

const self = process.argv.length < 3;
const version = (self ? process.version : process.argv[2]).replace(/^v/, '');
if (!/^\d+\.\d+\.\d+/.test(version)) {
  console.error(`Cannot parse Node.js version: ${version}`);
  process.exit(1);
}
const major = parse(version)[0];

const fail = [];
const warn = [];

if (FIXED[major]) {
  if (lessThan(version, FIXED[major])) {
    fail.push(`Node.js ${version} is vulnerable, including CVE-2026-111497 (Brotli decoder out-of-bounds write, possible RCE). Update to ${FIXED[major]} or later.`);
  }
} else if (major < LATEST_KNOWN_LINE) {
  fail.push(`Node.js ${major}.x is not a supported line; end-of-life versions are always affected by security releases. Upgrade to Node.js 22, 24 or 26.`);
} else {
  warn.push(`Node.js ${major}.x is newer than this check knows about; confirm it includes the fixes from ${ADVISORY}`);
}

if (!fail.length) {
  warn.push('If you build startup snapshots (--build-snapshot) or single executable applications, rebuild them with this version (CVE-2026-106074).');
}

console.log(`Node.js ${version}${self ? ` (${process.execPath})` : ''}`);
for (const msg of fail) console.log(`  [FAIL] ${msg}`);
for (const msg of warn) console.log(`  [WARN] ${msg}`);
if (fail.length) {
  console.log(`Result: FAIL - see ${ADVISORY}`);
  process.exit(1);
}
console.log('Result: PASS');
