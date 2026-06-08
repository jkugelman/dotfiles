---
name: live-notes
description: Maintain a running notes file during long-form conversations — captures what's been settled (with reasoning), open threads, parked topics, and the current focus, so the conversation can resume cleanly across sessions. Trigger when the user asks for live notes, a working doc, a place to track state as it accumulates, or anything that signals "keep state for me as we talk." Also trigger when the user asks to resume from a prior notes file.
---

# Live notes

A running notes file kept *during* a conversation, not after. Captures the evolving state of a discussion — what's been settled and *why*, what's still open, what was considered and set aside — so the conversation can be paused and resumed (in this session or a fresh one) without losing context.

The file is a working artifact, not a deliverable. It evolves continuously as the conversation progresses.

The conversation type is open-ended: design discussions, debugging exploration, code reviews, learning a new codebase, planning, research — anything where state accumulates across many turns and the user wants it preserved.

## When to use

Trigger when:
- The user explicitly asks ("save where we are," "keep notes as we talk," "track this for me," "I might jump us to a new session").
- A long-form conversation accumulates real outcomes over many turns and you can tell the user wants the state preserved.
- The user points at a prior notes file or asks to resume an earlier discussion (read the file first, then resume per its "If resuming" pointer).

Don't trigger for:
- Short tasks where the result lands directly in code.
- Conversations whose state will be obvious from the transcript or git history.
- Memory-type facts about the user (those go in actual memory, not notes).

## File location

**Default to a temporary location outside the project tree.** Notes are working artifacts, not deliverables — they shouldn't pollute git status or end up in commit history. A good default: `/tmp/<descriptive-name>.md` (e.g. `/tmp/grawlix-ui-brainstorm.md`).

Include the project name in the filename so the file is identifiable if the user resumes from a fresh session and needs to point you at it.

Don't place the file inside the project's `docs/`, `notes/`, or similar checked-in directories unless the user explicitly asks. If the user prefers in-project storage or a more durable location (e.g. `~/.claude/...`), ask once and remember the choice for the rest of the session.

Caveat for `/tmp`: most systems clean it on reboot. If the conversation is expected to span days/weeks, surface this and offer a more durable path.

## Standard structure

```markdown
# [Topic] — working notes

Live notes for [one-line description]. Edited as the conversation progresses.

If resuming in a new session: read this file, then [referenced docs], then pick up at "Current focus."

---

## Background

What this conversation is about. Scope. State of the world coming in. Framing for someone arriving fresh — they should be able to ramp in by reading just this section.

Cover, as relevant:
- What's being discussed.
- The current state (existing plans, code, prior docs — link them).
- Things explicitly under reconsideration.
- Comparison points / inspirations / prior art.
- Anything material the user mentioned in framing.

---

## Settled

Bulleted outcomes with the *why* preserved. Each bullet is self-contained: name what was settled, then the reasoning that drove it. Future sessions need to know not just what was concluded but why — so judgment calls about edge cases can be made faithfully.

"Settled" covers anything the conversation has resolved: decisions, agreed-upon facts, conclusions reached after exploration, choices about scope, etc.

---

## Open threads

Things raised but not yet engaged with — including questions you've asked the user that they haven't answered. When something gets picked up, move it to "Current focus." When something settles, move it to "Settled."

---

## Current focus

What's being discussed *right now*. The most volatile section — rewritten frequently. May include positions on the table, trade-offs, your recommendation, and sharpening questions.

---

## Parked

Topics or alternatives explicitly considered and set aside. Preserve the case for each (so a future revisit has the full picture). Distinguish:
- *Parked, may revisit* — set aside but could come back if circumstances change.
- *Rejected* — decided against on principle, not just punted.

For substantial choices where multiple options were evaluated, give them their own subsection (e.g., "Rail flavors considered" listing all options with status).
```

Sections in this order. Skip a section if it's genuinely empty, but prefer to leave it with a placeholder like "*(none yet)*" rather than removing it — the structure is what makes the file scannable.

## Maintenance protocol

Update the file *as* shifts happen, not at the end of the session. End-of-session batched updates lose nuance and turn live notes into summaries.

- **Something gets settled** → move from "Current focus" or "Open threads" to "Settled." Include the reasoning from the conversation, not just the outcome.
- **A new thread is mentioned but deferred** → add to "Open threads."
- **A topic is considered and explicitly set aside** → move to "Parked" with the case for it preserved. Don't just delete — preserved alternatives are the file's most durable value.
- **The current focus changes** → rewrite "Current focus" to reflect what's now being discussed. Don't accumulate dead branches there.
- **The user supplies parameters for something parked** → annotate the parked entry with those parameters, so a future revisit has the full picture.
- **The user changes their mind** → update the existing entry in place; don't add a contradicting one elsewhere.

When in doubt, prefer updating *during* the relevant turn (right after the user makes a shift) over waiting.

## Resuming an existing notes file

If you arrive in a session where a live-notes file exists or the user points you at one:

1. Read the file in full.
2. Read whatever docs it links to in the header / Background.
3. Pick up where the file points — usually at "Current focus."
4. Continue maintaining the file under the same protocol.

Don't re-litigate items in "Settled" unless the user explicitly opens them. Don't re-suggest things in "Parked" unless circumstances clearly changed.

## Tone and content

- **Terse, but include the *why*.** A bullet that says "Settled on X" is half-useless three months later. "Settled on X because Y, in response to Z constraint" survives.
- **Preserve the user's specific phrasing** for landed outcomes. If they said "I dislike accordions because items shift under the cursor," use that — don't paraphrase to "user prefers stable layouts."
- **Use markdown links** for cross-references to other docs.
- **Strikethrough sparingly** — only for items the user explicitly killed (`~~routes for everything~~`). For parked-may-revisit, use prose.
- **Scannable.** Bullets and short paragraphs. A reader skimming should land on the right section quickly. Don't bury outcomes under prose.

## Common slip-ups

- **End-of-session batching.** Notes drift from "live" to "summary" and lose the reasoning. Update as you go.
- **Conflating rejected with parked.** Different statuses, different futures. Keep them distinct.
- **Dropping the why** because the reason feels obvious now. It won't be obvious to future-you.
- **Stale "Current focus."** Rewrite it whenever the topic shifts; don't let it accumulate dead branches.
- **Losing things the user raised but didn't engage with.** Those go in "Open threads," not into the void.
- **Writing notes the user might not see.** This is a shared artifact — phrasing matters. Avoid slipping into private-to-Claude shorthand.
