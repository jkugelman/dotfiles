#!/usr/bin/env node
// syntax-check-hook.js — PostToolUse hook for Edit/Write/MultiEdit.
//
// After an edit to a .js, .mjs, .cjs, .html or .htm file, runs
// check-syntax.js on the file and tells Claude about any syntax errors.
// Silent when the file parses.
//
// It runs after the edit, so it never stops one: an intentionally invalid
// state (a midway step of a multi-edit change, a broken-on-purpose fixture)
// goes through, and Claude can carry on past the report.
//
// Any internal failure exits 0 silently.

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const EXTS = new Set(['.js', '.mjs', '.cjs', '.html', '.htm']);

try {
  const input = JSON.parse(fs.readFileSync(0, 'utf8'));
  const file = input.tool_input && input.tool_input.file_path;
  if (!file || !EXTS.has(path.extname(file).toLowerCase())) process.exit(0);
  if (!fs.existsSync(file)) process.exit(0);

  const checker = path.join(__dirname, 'check-syntax.js');
  const r = spawnSync(process.execPath, [checker, file], { encoding: 'utf8', timeout: 20000 });
  if (r.status !== 1) process.exit(0);

  const reason =
    `Syntax check failed after this edit (check-syntax.js):\n${r.stderr.trim()}\n\n` +
    'Fix it, unless the invalid state is intentional (a step partway through a ' +
    'multi-edit change, or a file meant to be invalid). The edit has already ' +
    'been applied; if it is intentional, carry on and ignore this report.';
  process.stdout.write(JSON.stringify({ decision: 'block', reason }));
} catch {
  process.exit(0);
}
