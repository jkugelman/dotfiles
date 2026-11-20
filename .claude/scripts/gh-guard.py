#!/usr/bin/env python3
"""gh-guard.py — PreToolUse hook for Bash.

Denies two `gh` invocations that silently do the wrong thing:

  - `gh run list --commit <sha>` with a short SHA. The flag matches only a
    full 40-character SHA, so a short one returns [] as if CI had not
    started. A `$(...)` substitution passes through.
  - `gh markdown-preview` without `--markdown-mode`. The default, gfm,
    renders the way GitHub comments do, turning every line break into <br>.

Any internal failure exits 0 silently (allow).
"""

import json
import re
import shlex
import sys

FULL_SHA = re.compile(r"[0-9a-f]{40}", re.IGNORECASE)


def check(cmd):
    if not re.search(r"\bgh\b", cmd):
        return None
    for segment in re.split(r"&&|\|\||[;|\n]", cmd):
        try:
            words = shlex.split(segment)
        except ValueError:
            words = segment.split()
        if "gh" not in words:
            continue
        args = words[words.index("gh") + 1 :]
        if args[:2] == ["run", "list"]:
            for i, w in enumerate(args):
                if w in ("--commit", "-c") and i + 1 < len(args):
                    sha = args[i + 1]
                elif w.startswith("--commit="):
                    sha = w.split("=", 1)[1]
                else:
                    continue
                if "$" not in sha and not FULL_SHA.fullmatch(sha):
                    return (
                        f"`gh run list --commit` needs the full 40-character "
                        f"SHA; `{sha}` matches nothing and returns []. Use "
                        f'--commit "$(git rev-parse {sha})".'
                    )
        if args[:1] == ["markdown-preview"] and not any(
            a.startswith("--markdown-mode") for a in args
        ):
            return (
                "Pass --markdown-mode to `gh markdown-preview`. The default, "
                "gfm, renders like a GitHub comment and turns every line "
                "break into <br>; --markdown-mode renders the way GitHub "
                "shows a file."
            )
    return None


def main():
    data = json.load(sys.stdin)
    cmd = (data.get("tool_input") or {}).get("command") or ""
    reason = check(cmd)
    if reason:
        print(
            json.dumps(
                {
                    "hookSpecificOutput": {
                        "hookEventName": "PreToolUse",
                        "permissionDecision": "deny",
                        "permissionDecisionReason": reason,
                    }
                }
            )
        )


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
