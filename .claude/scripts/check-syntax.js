#!/usr/bin/env node
// Syntax-check JS files or inline <script> blocks in HTML files.
// Usage: node scripts/check-syntax.js <file> [<file> ...]
//        cat foo.js | node scripts/check-syntax.js   (reads JS from stdin)

const fs = require('fs');
const path = require('path');
const vm = require('vm');

const SCRIPT_RE = /<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/gi;

function lineOf(source, index) {
  return source.slice(0, index).split('\n').length;
}

function checkSource(label, source) {
  try {
    new vm.Script(source, { filename: label });
    return null;
  } catch (e) {
    return e.message.split('\n')[0];
  }
}

function checkFile(file) {
  const text = fs.readFileSync(file, 'utf8');
  const ext = path.extname(file).toLowerCase();
  const blocks = [];
  if (ext === '.html' || ext === '.htm') {
    let m;
    while ((m = SCRIPT_RE.exec(text))) {
      blocks.push({ label: `${file}:${lineOf(text, m.index)}`, source: m[1] });
    }
  } else {
    blocks.push({ label: file, source: text });
  }
  return blocks;
}

const args = process.argv.slice(2);
const blocks = [];

if (args.length === 0) {
  if (process.stdin.isTTY) {
    console.error('usage: check-syntax.js <file> [<file> ...]   (or pipe JS to stdin)');
    process.exit(2);
  }
  blocks.push({ label: '<stdin>', source: fs.readFileSync(0, 'utf8') });
} else {
  for (const file of args) blocks.push(...checkFile(file));
}

let errors = 0;
for (const { label, source } of blocks) {
  const err = checkSource(label, source);
  if (err) {
    errors++;
    console.error(`${label}: ${err}`);
  }
}

console.log(`${blocks.length} script${blocks.length === 1 ? '' : 's'}, ${errors} error${errors === 1 ? '' : 's'}`);
process.exit(errors ? 1 : 0);
