---
name: audit-overbuild
description: Use when the user asks to audit work for overbuilding, scope creep, or unrequested complexity. Audits a commit range against what the user actually asked for, plus its structure, and walks each finding with them to cut, simplify or keep. Its findings can cut or simplify features, not only restructure them.
---

# Audit for overbuilding

An audit of a body of work, usually a branch's unpushed commits, against what the user asked for.
It finds what was built beyond the asks or beyond what a feature needs, and the structure that makes the code harder to change.
The user decides each finding: cut, simplify, or keep.
Then the decisions are applied in one pass.

A refactor that preserves behavior can't see overbuilding: the extra behavior is part of what it preserves.
The yardstick here is the user's requests, so a feature itself can be cut.

## 1. Gather the asks

- **The range.** Default to the unpushed commits: `git log @{upstream}..HEAD`, or from the merge-base with the default branch.
- **The asks, in the user's words.** Take them from this conversation; when it's gone, from the session transcripts (`~/.claude/projects/<project>/*.jsonl`, the user's messages), commit messages, the PR description and the ticket.
  Include the changes they asked for along the way, and their standing preferences from CLAUDE.md.
- **Show the list and let the user correct it** before auditing. A wrong yardstick spoils the audit.

## 2. Audit in parallel

Run read-only subagents, giving each the range, the asks and the code, not your own opinions of it.
Split a large range by area, such as server and client.

- **Overbuild, one per area.** Find unrequested behaviors, clever handling where default behavior would do, speculative generality, machinery out of proportion to its feature, and duplicated logic.
  Each finding: `file:line`, what it costs in lines, the simpler alternative, what that would lose, and a verdict (cut, simplify or keep) with its reason.
  Keep what the feature needs, and say why.
  Rank by how much a cut removes.
- **Structure, one for the range.** Ask of the changed code "should these pieces change together?" and list every hidden link (copies of logic, implicit conventions, related code split apart), needless link (callers on internals, a general function with one caller's parameter), surplus (pass-through wrappers, unused extension points, dead code) and special case (an `if` for one value, a parameter for one caller, a swallowed exception, a retry or sleep).
  Then propose fixes as if today's requirements had been known from the start, each written above the problems it solves.
  This is steps 2 and 3 of [untangle-codebase](https://github.com/caldoai/skills/blob/main/skills/untangle-codebase/SKILL.md), with no fixing.

## 3. Merge and verify

- Merge the reports: one finding per thing to decide, the overbuild and structural angles on the same code together.
- Verify each against the code before presenting it, and drop what doesn't hold.
- Order by how much complexity a decision removes, biggest first. A bug the audit found ranks by its severity.
- Write the findings to a file in the scratch directory, and record each decision there as it's made, so the walk survives compaction.

## 4. Walk the findings

One finding per message; wait for the user's decision before the next.

1. **The finding**, bolded, with its size: "**Hand-written local-variable lookup, about 260 lines.**"
2. **What it is:** the code, with `file:line` links, in terms the user can judge without reading it.
3. **The simpler alternative:** what goes, and what the user would see change or lose.
4. **Your recommendation,** and the question: cut, simplify, or keep. Parts of one finding can go different ways.

Change no code during the walk.
Say how many findings there are when you start.

## 5. Apply

After the walk, and after the user compacts if they want to, apply every decision from the file:

- A test with each change, failing without it.
- Docs updated wherever they describe what changed.
- Commits that each ship on their own. When the commit that added the code is unpushed, fold a cut into it if that's clean.
- The full test suite, then a report of what changed.
