---
description: Write a handoff doc capturing this session's state so a fresh session can resume without re-reading the whole conversation.
argument-hint: [output-path]
---

This session's context window is filling up. Produce a **handoff document** so a
brand-new session — which will have NONE of this conversation in its context —
can pick up exactly where we are. This is the cheaper alternative to `/compact`:
write the state down deliberately instead of having the next session re-ingest
the whole transcript.

## Where to write it

- Let `<dir>` be the basename of the current working directory (`basename "$PWD"`).
- Output path: use `$ARGUMENTS` if non-empty; otherwise default to
  `/tmp/handoff-<dir>.md`.
- After writing the doc, record its absolute path into the pointer file
  `/tmp/handoff-last-<dir>.path` (overwrite it — the latest handoff wins). This
  lets the next session run `/resume` with no argument and find this doc
  automatically.
- Then print the doc's path and tell the user the next session can simply run
  `/resume` (no path needed). Mention they can pass an explicit path to either
  command if they're juggling multiple handoffs.

## Before you write

Run `git status` and `git log --oneline -8` so the "Work done" section reflects
the real tree state (staged vs. unstaged, recent commits). Otherwise rely on the
conversation already in your context — do **not** re-read files you've already
read unless you need to confirm a current line number. The whole point is to
spend tokens writing, not re-reading.

## What goes in it

Write for a competent peer who knows this codebase and has the project's
CLAUDE.md, but knows nothing about *this conversation*. Do NOT restate things
already in CLAUDE.md, the docs, or git history — point to them instead. Capture
only what would be lost when this context window closes. Use these sections,
omitting any that are empty:

1. **Goal** — what we set out to do, in a sentence or two.
2. **Status now** — where we actually are: done / in progress / not started.
3. **Decisions & rationale** — choices made and *why*, plus options considered
   and rejected, so the next session doesn't relitigate them.
4. **Work done** — files touched (with paths), commits made (hash + subject),
   approaches tried. Flag what's committed vs. still staged/unstaged.
5. **Next steps** — an ordered, concrete to-do list, specific enough to act on.
6. **Open questions** — unresolved threads and anything waiting on the user.
7. **Gotchas** — dead ends, things that failed and why, constraints, and
   non-obvious context that can't be recovered from the code.
8. **Pointers** — key files / functions / docs with `path:line` anchors.

Keep it tight and skimmable: headings and bullets, not walls of prose. Favor
state that carries forward over narration of how we got here.
