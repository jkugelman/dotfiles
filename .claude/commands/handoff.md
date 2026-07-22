---
description: Write a handoff doc capturing session state (default), or resume from one written earlier with `/handoff resume`.
argument-hint: [output-path] | resume [handoff-path]
---

`$ARGUMENTS` selects the mode:

- First whitespace-separated token is literally `resume` → **Resume** (below),
  with the rest of `$ARGUMENTS` as the optional handoff path.
- Anything else (including empty) → **Write** (below), with all of
  `$ARGUMENTS` as the optional output path.

## Write

This session's context window is filling up. Produce a **handoff document** so a
brand-new session — which will have NONE of this conversation in its context —
can pick up exactly where we are. This is the cheaper alternative to `/compact`:
write the state down deliberately instead of having the next session re-ingest
the whole transcript.

### Where to write it

- Let `<dir>` be the basename of the current working directory (`basename "$PWD"`).
- Output path: use `$ARGUMENTS` if non-empty; otherwise default to
  `/tmp/handoff-<dir>.md`.
- After writing the doc, record its absolute path into the pointer file
  `/tmp/handoff-last-<dir>.path` (overwrite it — the latest handoff wins). This
  lets the next session run `/handoff resume` with no argument and find this
  doc automatically.
- Then print the doc's path and tell the user the next session can simply run
  `/handoff resume` (no path needed). Mention they can pass an explicit path to
  either mode if they're juggling multiple handoffs.
- **Colliding with a *different, still-active* effort?** If the default path (or
  the pointer) already holds a handoff for a separate concurrent effort in this
  same repo — not just a stale prior handoff of your own lineage — do **not**
  silently overwrite it, and do **not** silently shunt yours to a side filename
  hoping the pointer sticks (the pointer is single-slot and "latest wins", so a
  side-filed handoff gets orphaned the moment the other effort writes its own).
  Flag the collision to the user and agree on how to name the two and which one
  the pointer should track.

### Before you write

Run `git status` and `git log --oneline -8` so the "Work done" section reflects
the real tree state (staged vs. unstaged, recent commits). Otherwise rely on the
conversation already in your context — do **not** re-read files you've already
read unless you need to confirm a current line number. The whole point is to
spend tokens writing, not re-reading.

**One exception to "don't re-read": if a handoff already exists at your target
output path, read that one file first.** You need its *Parked / deferred*
section to carry forward (below) — it holds long-lived items that predate this
session and would otherwise be lost the moment you overwrite the file. It's one
small doc, not a source tree; read it.

### What goes in it

Write for a competent peer who knows this codebase and has the project's
CLAUDE.md, but knows nothing about *this conversation*. Do NOT restate things
already in CLAUDE.md, the docs, or git history — point to them instead. Capture
only what would be lost when this context window closes. Use these sections,
omitting any that are empty (except *Parked / deferred* — always keep that one,
even if only to record "(none)"):

1. **Goal** — what we set out to do, in a sentence or two.
2. **Status now** — where we actually are: done / in progress / not started.
3. **Decisions & rationale** — choices made and *why*, plus options considered
   and rejected, so the next session doesn't relitigate them.
4. **Work done** — files touched (with paths), commits made (hash + subject),
   approaches tried. Flag what's committed vs. still staged/unstaged.
5. **Next steps** — an ordered, concrete to-do list for the *immediate*
   continuation of active work, specific enough to act on.
6. **Parked / deferred** — known future work you are *not* actively pursuing
   right now: deferred deliverables, tabled ideas, parked plans, "later" items.
   Each gets a one-line pointer to where its detail lives (a `/tmp` or
   `docs/planned/` doc, a commit, an issue). **This section is carry-forward,
   not freshly written:** harvest it from the previous handoff (see *Before you
   write*) and copy every item over unless it has since shipped or the user
   explicitly dropped it. An item leaves this section *only* by shipping or
   cancellation — never because it went untouched this session or slipped your
   mind. It is the one region that must survive the rewrite intact. It stays
   bounded on its own: items exit as they ship, so it can't grow without end.
   If a parked item has sat here untouched across several handoffs, flag that to
   the user — they may want to act on it, drop it, or move its detail somewhere
   more durable — rather than letting it ride silently forever.
7. **Open questions** — unresolved threads and anything waiting on the user.
8. **Gotchas** — dead ends, things that failed and why, constraints, and
   non-obvious context that can't be recovered from the code.
9. **Pointers** — key files / functions / docs with `path:line` anchors.

Keep it tight and skimmable: headings and bullets, not walls of prose. Favor
state that carries forward over narration of how we got here.

## Resume

Pick up a working session from a handoff document written by **Write** (above)
in a previous session.

### Find the handoff

Let `<dir>` be the basename of the current working directory (`basename "$PWD"`).
Resolve the handoff path in this order:

1. If a path was given after `resume`, use that path.
2. Else, if the pointer file `/tmp/handoff-last-<dir>.path` exists, use the path
   stored inside it. (This is how a no-argument `/handoff` → `/handoff resume`
   transfers the filename automatically.)
3. Else fall back to `/tmp/handoff-<dir>.md`.
4. If the resolved file doesn't exist, list `/tmp/handoff-*.md` (newest first)
   and any obvious in-repo candidate, then ask which one to use rather than
   guessing.

### Orient, then continue

1. Read the handoff doc in full.
2. Run `git status` and `git log --oneline -8` to confirm the tree matches what
   the doc describes. Flag any drift (e.g. the doc says a change is unstaged but
   it's since been committed, or vice versa).
3. Give the user a tight orientation — goal, where things stand, and the
   immediate next step from the doc — in a few lines, not a wall of prose.
   **Always surface the doc's "Parked / deferred" section too, even when it
   isn't what you're about to work on.** Those are long-lived items that decay
   out of the handoff chain precisely because no single session is actively
   pushing them; a one-line "still parked: X, Y" in your orientation keeps them
   visible. If the doc has no such section at all, say so — an older handoff
   predating this convention may have silently dropped deferred work, and the
   user may want to reconstruct it.
4. Once you've read the doc and oriented (before doing the actual work), clean
   up the pointer file: delete `/tmp/handoff-last-<dir>.path` if it exists. The
   handoff has been consumed, so a stray re-run of `/handoff resume` shouldn't
   silently pick up a stale pointer. Leave the handoff doc itself in place. (If
   an explicit path was given after `resume`, still clear the pointer.)
5. State the specific next action you're about to take. If it's unambiguous and
   doesn't need a decision, proceed. If the next step is a fork or needs the
   user's input, ask before acting. **If the recorded next step is vague or
   missing** (e.g. "ask the user what's next", "last task unstated"), check the
   "Parked / deferred" section before asking the user to reconstruct it from
   memory — the answer is often already written down there.

Treat the doc's decisions as already settled — don't relitigate choices it
records unless something in the current tree contradicts them.
