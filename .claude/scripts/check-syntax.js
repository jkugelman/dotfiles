#!/usr/bin/env node
// Syntax-check JS files or inline <script> blocks in HTML files.
// Usage: node scripts/check-syntax.js <file> [<file> ...]
//        cat foo.js | node scripts/check-syntax.js   (reads JS from stdin)
//
// .mjs files and <script type="module"> blocks parse as ES modules. A .js
// file parses as a classic script and, failing that, as a module, since its
// kind depends on package.json. HTML blocks with a non-JS type (JSON,
// importmap, templates) are skipped.

const fs = require('fs');
const path = require('path');
const vm = require('vm');
const { spawnSync } = require('child_process');

const SCRIPT_RE = /<script(?![^>]*\bsrc=)([^>]*)>([\s\S]*?)<\/script>/gi;
const TYPE_RE = /\btype\s*=\s*["']?([^"'\s>]+)/i;
const JS_TYPES = /^(text|application)\/(x-)?(javascript|ecmascript)$/i;
const ESM_RE = /^\s*(import|export)\b/m;

function lineOf(source, index) {
  return source.slice(0, index).split('\n').length;
}

function scriptError(label, source) {
  try {
    new vm.Script(source, { filename: label });
    return null;
  } catch (e) {
    return e.message.split('\n')[0];
  }
}

// vm.SourceTextModule needs a flag, so parse modules with `node --check`.
function moduleError(source) {
  const r = spawnSync(process.execPath, ['--check', '--input-type=module', '-'], {
    input: source,
    encoding: 'utf8',
  });
  if (r.status === 0) return null;
  const line = (r.stderr.match(/^\[stdin\]:(\d+)/m) || [])[1];
  const msg = (r.stderr.match(/^\w*Error: .*$/m) || [r.stderr.trim()])[0];
  return line ? `line ${line}: ${msg}` : msg;
}

function checkSource({ label, source, kind }) {
  if (kind === 'module') return moduleError(source);
  const err = scriptError(label, source);
  if (!err || kind === 'script') return err;
  // kind 'either': a .js file may be a module.
  const modErr = moduleError(source);
  if (!modErr) return null;
  return ESM_RE.test(source) ? modErr : err;
}

function checkFile(file) {
  const text = fs.readFileSync(file, 'utf8');
  const ext = path.extname(file).toLowerCase();
  const blocks = [];
  if (ext === '.html' || ext === '.htm') {
    let m;
    SCRIPT_RE.lastIndex = 0;
    while ((m = SCRIPT_RE.exec(text))) {
      const type = (m[1].match(TYPE_RE) || [])[1];
      let kind;
      if (!type || JS_TYPES.test(type)) kind = 'script';
      else if (type.toLowerCase() === 'module') kind = 'module';
      else continue;
      blocks.push({ label: `${file}:${lineOf(text, m.index)}`, source: m[2], kind });
    }
  } else {
    const kind = ext === '.mjs' ? 'module' : ext === '.cjs' ? 'script' : 'either';
    blocks.push({ label: file, source: text, kind });
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
  blocks.push({ label: '<stdin>', source: fs.readFileSync(0, 'utf8'), kind: 'either' });
} else {
  for (const file of args) blocks.push(...checkFile(file));
}

let errors = 0;
for (const block of blocks) {
  const err = checkSource(block);
  if (err) {
    errors++;
    console.error(`${block.label}: ${err}`);
  }
}

console.log(`${blocks.length} script${blocks.length === 1 ? '' : 's'}, ${errors} error${errors === 1 ? '' : 's'}`);
process.exit(errors ? 1 : 0);
