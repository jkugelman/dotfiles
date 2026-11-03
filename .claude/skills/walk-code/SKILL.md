---
name: walk-code
description: Use when the user asks for a code walk, a walkthrough, or to be walked through code — usually code you wrote or changed in this session, after a big round of edits, but also a branch, commit range, or unfamiliar subsystem. Covers choosing the scope, ordering chunks by concept rather than file order, the shape of one chunk (snippets with clickable VS Code links, the design choices worth a second look), and pausing for the user after each chunk.
---

# Walk code

A code walk shows the user a body of code one concept at a time, so they can
review it the way they'd review a PR, with you as the guide. Each chunk ends
with a stop: the user reads, asks questions or requests changes, and says when
to go on.

## Scope

State the scope in the first line: which commits, files, or feature the walk
covers, and how many chunks it will take. When the request is ambiguous, pick
the most likely scope (usually the work the user hasn't reviewed yet), say so,
and offer the alternative in one line. Don't ask first.

## Order

Order by concept, not by file or line. Start where a reader would: what a user
of the code writes or calls. Then follow the data or control flow through the
system, then the supporting machinery, then tests, then docs. Each chunk should
make sense given only the chunks before it.

Plan the chunk list before the first chunk and keep it fixed, so "chunk 3 of 6"
stays true.

## One chunk

1. **Heading**: `## Chunk N of M: <concept>`.
2. **What it is**, in a sentence or two.
3. **Snippets**, each under a clickable link to the exact line:
   `[file.rs:148](vscode://file/<absolute path>:148)`. Use the absolute path
   of the checkout you're working in, including a worktree. Quote the code
   verbatim from the current file. Trim with `// ...`, never paraphrase.
4. **Why it's shaped this way**: the design choices a reviewer might question,
   and the alternatives you weighed, briefly. Flag weak spots, known limits,
   and anything you're unsure of; the walk is the user's review.
5. **Stop.** One line naming the next chunk, then wait.

Get line numbers from the current tree (`grep -n`) right before each chunk.
Edits made mid-walk shift them.

Keep a chunk to about one screen. Split a concept that won't fit.

## Changes during the walk

When the user asks for a change, make it, run the relevant checks, commit it
where it belongs (amend into the commit it fixes when unpushed), and resume
the walk at the chunk you were on. Mention the change in one line at the top
of the next chunk.

## Common mistakes

| Mistake | Fix |
|---|---|
| Walking files top to bottom | Order by concept; start from what a caller writes |
| Several chunks in one message | One chunk, then stop |
| Bare `file:line` text | A `vscode://file/` link with the absolute path |
| Paraphrased or stale snippets | Quote the current file; re-grep line numbers |
| Only describing what the code does | Say why it's shaped that way and where it's weak |
