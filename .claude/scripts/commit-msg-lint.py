#!/usr/bin/env python3
"""commit-msg-lint.py — PostToolUse hook for Bash.

After a Bash command that runs `git commit` or `dotfiles commit`, reads the
message of the commit it made and asks Claude to amend it if:

  - a body line is wider than 72 columns, unless it is one unbreakable token
    (a URL, a path) or indented 4+ spaces (a code block), or
  - it carries an AI-attribution trailer (Co-Authored-By, Claude-Session,
    "Generated with Claude Code").

The commit it reads is HEAD of the repo the command ran in, and only when
HEAD was committed in the last two minutes, so a failed commit or a command
that merely mentions "commit" lints nothing.

Any internal failure exits 0 silently.
"""

import json
import os
import re
import shlex
import subprocess
import sys
import time

WIDTH = 72
RECENT_SECONDS = 120
COMMIT_RE = re.compile(r"\b(git|dotfiles)\b[^;&|\n]*\bcommit\b")
TRAILER_RE = re.compile(
    r"^\s*(co-authored-by|claude-session|generated-by|assisted-by)\s*:"
    r"|noreply@anthropic\.com"
    r"|generated with \[?claude",
    re.IGNORECASE,
)


def repo_args(cmd, cwd):
    """Git arguments selecting the repo `cmd` committed in."""
    home = os.path.expanduser("~")
    if re.search(r"\bdotfiles\b[^;&|\n]*\bcommit\b", cmd) or ".dotfiles" in cmd:
        return [f"--git-dir={home}/.dotfiles", f"--work-tree={home}"]
    try:
        words = shlex.split(cmd)
    except ValueError:
        words = cmd.split()
    target = None
    for i, w in enumerate(words[:-1]):
        if w == "-C":
            target = words[i + 1]
            break
    if target is None and len(words) > 1 and words[0] == "cd":
        target = words[1]
    if target:
        target = os.path.expanduser(target)
        cwd = os.path.join(cwd, target)
    return ["-C", cwd]


def problems(message):
    lines = message.rstrip("\n").split("\n")
    found = []
    for n, line in enumerate(lines, 1):
        if TRAILER_RE.search(line):
            found.append(f"line {n}: attribution line: {line.strip()}")
        if n < 3 or len(line) <= WIDTH:
            continue
        if line.startswith("    ") or len(line.split()) <= 1:
            continue
        found.append(f"line {n}: {len(line)} columns (max {WIDTH})")
    return found


def main():
    data = json.load(sys.stdin)
    cmd = (data.get("tool_input") or {}).get("command") or ""
    if not COMMIT_RE.search(cmd):
        return
    cwd = data.get("cwd") or os.getcwd()
    out = subprocess.run(
        ["git", *repo_args(cmd, cwd), "log", "-1", "--format=%ct%n%B"],
        capture_output=True,
        text=True,
        timeout=10,
    )
    if out.returncode != 0:
        return
    stamp, _, message = out.stdout.partition("\n")
    if time.time() - int(stamp) > RECENT_SECONDS:
        return
    found = problems(message)
    if not found:
        return
    reason = (
        "The commit just made breaks the commit-message rules in CLAUDE.md:\n"
        + "\n".join(f"  - {p}" for p in found)
        + f"\nAmend it: hard-wrap the body at {WIDTH} columns and remove "
        "any attribution lines."
    )
    print(json.dumps({"decision": "block", "reason": reason}))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
