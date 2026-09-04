---
name: distill-writeup
description: Use when a bug report, investigation writeup, PR/ticket description, or subagent report reads as longer or more complicated than the underlying problem, buries its conclusion or recommendation, or needs review before posting — including a writeup someone else wrote, not just your own. Also use when told a writeup is "too long," "too complicated," or "I can't tell what to do from this."
---

# Distill Writeup

## Overview

A writeup is distilled when a reader can act on it without reading past the
point where they already have what they need. Writeups — AI-written ones
especially — tend to accumulate every finding, dead end, and hedge from the
investigation instead of reporting only what the reader needs. Length is
itself a claim about how complicated the problem was: an over-long writeup
misrepresents a one-line fix as a hard problem.

## When to use

- Reviewing a writeup (yours or someone else's) that reads harder than the
  underlying problem should be
- Before posting a bug report, ticket comment, PR description, or subagent
  report that summarizes an investigation
- Given a path, URL, or pasted text: read it, identify the actual reader (ask
  if genuinely unclear), rewrite per the contract below, and show the rewrite
  for review — don't overwrite or post anything without confirmation,
  especially for someone else's writeup

Not for live back-and-forth explanation in chat — walk through detail there;
don't pre-trim it.

## What a distilled writeup contains, in order

1. **The finding and the fix** (or best current recommendation), in the
   reader's own terms — not the investigator's process. No fix yet? State the
   clearest conclusion so far in its place.
2. **One causal thread**: symptom → mechanism → (root cause) → fix, as
   connected prose. Not a list of everything that was investigated.
3. **Optionally, one section after 1 and 2**, clearly separated, for anything
   a different downstream reader might need — supporting evidence, why an
   earlier assumption doesn't hold, version/history context. Never
   interleaved with 1 and 2.

Nothing else. A sentence that doesn't advance the thread in (2) or correct
something the reader currently believes wrong doesn't appear — not in the
lead, not in the secondary section, not as a footnote "for completeness."

## Process

1. **Work out who's actually reading this.** Not "a lay audience" — model
   their real, specific expertise. Someone whose own ticket cites SQL filters
   and packet captures already knows what a TCP handshake is. Someone who's
   never touched the codebase doesn't need internal type names explained —
   they need them left out entirely.
2. **Find the one throughline.** Several things investigated? Pick the thread
   that leads to the fix or conclusion. Everything else is the secondary
   section, or gets cut.
3. **Draft, then trim in a separate pass.** A first pass drafted right after
   finishing an investigation over-includes — everything still feels
   relevant because it's fresh, not because it matters. Come back to it (a
   fresh subagent with no investigation history trims better than the one
   that did the digging) and, per sentence: *if this were deleted, would the
   reader's next action change, or would they believe something false in a
   way that would change what they do?* If neither, cut it — even if it's
   true, even if it's interesting, even if leaving it out feels like
   understating how sure you are. "This makes me look more certain than I
   am" is not a reason to keep a sentence. State the finding as fact and
   stop; don't append how you know it or what you didn't get to check
   unless the answer to that specific gap would change the recommendation.
4. **Check the length against the actual problem.** A one-line fix should
   read like a one-line fix.

## Example

**Bloated:** "I investigated this extensively and found that the ingestion
path, after tracing through several call sites, ultimately relies on a
fallback heuristic when no authoritative determination is available, and
although the upstream tool does appear to carry relevant directional
metadata in its event log, that metadata is not currently consumed anywhere
in the code, which means the fallback — which compares IP addresses
numerically — ends up being used instead, and this fallback is unreliable
because..."

**Distilled:** "The upstream tool already tags each event with the correct
direction. Our ingestion path ignores that tag and falls back to comparing
IP addresses numerically instead — wrong whenever the server's address
happens to be the higher one. Fix: use the upstream tool's own tag."

## Common mistakes

| Mistake | Fix |
|---|---|
| Explaining background the reader already has | Model their real expertise; cut what they already know |
| Narrating the investigation ("I tested X, then checked Y...") | That's provenance, not conclusion. Report the finding |
| Adding "I confirmed this by testing it live" after a finding | Cut it even when the testing was the hard part. State the finding as fact |
| Keeping an unconfirmed side question "for completeness," or "worth double-checking before you proceed" | If it doesn't change the recommendation, cut it — don't downgrade it to a footnote instead |
| Meta-commentary like "stop here if you just need the fix" | Structure it so that's obvious without saying so |
| Forcing every writeup into one fixed template | The throughline differs each time — only the contract above is fixed |
