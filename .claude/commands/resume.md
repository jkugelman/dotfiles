---
description: Read a handoff doc written by /handoff and pick up the previous session's work where it left off.
argument-hint: [handoff-path]
---

Pick up a working session from a handoff document written by `/handoff` in a
previous session.

## Find the handoff

Let `<dir>` be the basename of the current working directory (`basename "$PWD"`).
Resolve the handoff path in this order:

1. If `$ARGUMENTS` is non-empty, use that path.
2. Else, if the pointer file `/tmp/handoff-last-<dir>.path` exists, use the path
   stored inside it. (This is how a no-argument `/handoff` → `/resume` transfers
   the filename automatically.)
3. Else fall back to `/tmp/handoff-<dir>.md`.
4. If the resolved file doesn't exist, list `/tmp/handoff-*.md` (newest first)
   and any obvious in-repo candidate, then ask which one to use rather than
   guessing.

## Orient, then continue

1. Read the handoff doc in full.
2. Run `git status` and `git log --oneline -8` to confirm the tree matches what
   the doc describes. Flag any drift (e.g. the doc says a change is unstaged but
   it's since been committed, or vice versa).
3. Give the user a tight orientation — goal, where things stand, and the
   immediate next step from the doc — in a few lines, not a wall of prose.
4. Once you've read the doc and oriented (before doing the actual work), clean
   up the pointer file: delete `/tmp/handoff-last-<dir>.path` if it exists. The
   handoff has been consumed, so a stray re-run of `/resume` shouldn't silently
   pick up a stale pointer. Leave the handoff doc itself in place. (If the user
   passed an explicit `$ARGUMENTS` path, still clear the pointer.)
5. State the specific next action you're about to take. If it's unambiguous and
   doesn't need a decision, proceed. If the next step is a fork or needs the
   user's input, ask before acting.

Treat the doc's decisions as already settled — don't relitigate choices it
records unless something in the current tree contradicts them.
