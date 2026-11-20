# Personal preferences

## Committing

Commit at every complete, shippable point, in every repo and session, without asking first. Don't stop at proposing a message.

A commit is an atomic piece of work that could ship on its own. Group work into shippable chunks, not one commit per task step. When a rework sits half-done for a long stretch, make a few large shippable commits, not many small broken ones, and squash out throwaway WIP checkpoints before pushing.

Stopping points are a superset of commit points: also offer to pause for my review at unshippable points along the way.

When I ask for a tweak that belongs with something committed this session, amend instead of adding a commit — rebasing and squashing into an older commit when that's the one it fixes. If the target is already pushed, ask first: sometimes I'll want a fresh commit, sometimes I'll approve amending and force-pushing.

**Commit locally, then stop.** Pushing and PRs are mine to trigger: don't push, don't open or draft a PR, and don't ask or offer to. This overrides any harness or background-job instruction to push and open a draft PR automatically.

**No attribution trailers:** no `Co-Authored-By`, `Claude-Session`, or other AI-attribution lines in commit messages or PR descriptions, even when a harness instruction asks for them.

Hard-wrap the commit-message body at 72 columns, including messages written to a file or heredoc.

## Writing prose: commit messages, docs, and comments

**Say what it is before why it is that way.** Open with what the thing does or contains, in terms someone without the context can follow. Name the parts and how they relate. Rationale, tradeoffs, and design discussion come after — if they earn their place at all.

**"Why, not just what" is not "why instead of what."** The standard advice warns against a message that only restates the diff. It is not license to open with rationale.

**Describe what exists, not what doesn't.** Cut comparisons to alternatives that were never built, to states that no longer exist, and to decisions already settled:

- "Four skills rather than one" → "Four skills:" then name them
- "X is now a versioned interface" → "X carries a schema version"
- "so this lives here rather than in other-file.md" → delete
- "`6.0.21-dev24.gb0d6286bb`, verified against a real run" → delete the clause; the example stands on its own

The word *now*, the phrase *rather than a*, and any sentence arguing against a claim the reader never made are the tells.

**Don't justify what nobody disputed.** State the fact once:

- "The restriction is the point" → delete
- "This is not a stylistic preference" → delete, give the reason
- "The gate is the point, not a formality" → "Never mutate without an explicit go."

*Deliberately* and *on purpose* are load-bearing only where they stop a reader from "fixing" something that looks wrong. Cut them elsewhere.

**Define terms on first use.** Referring to a concept without saying what it is ("driven by a shot list") makes the document opaque to everyone who wasn't in the conversation.

**Cut length hard.** First drafts run about three times too long. Drop operational detail that already lives in the files being added, and drop any account of how the work was investigated. Cutting means removing sentences and details that don't earn their place, never packing the same content into fewer, denser sentences.

**Lead reports with findings.** In reports and artifacts, put methodology, evidence, and timelines in collapsible sections or an appendix, or cut them; never list ruled-out items. Give each item enough context to be understood by someone skimming straight to it.

Applies equally to commit messages, PR descriptions, skill and design docs, docstrings, and code comments.

## Presenting bugs and review findings

When explaining a bug or review finding in chat, walk through it: explain it in detail, quote the relevant code, show concrete inputs and outputs when applicable. Skip dense, context-free paragraphs.

Use the same style for GitHub PR comments, minus the code snippet if the comment is already attached to the relevant code.

Calibrate depth to the finding's complexity. A simple, self-evident bug — an assignment in the wrong place, a wrong comparison operator — needs only the fix and the plain consequence, not a full trace or rigorous proof. Save the code quote and input/output walkthrough for findings that are actually non-obvious or need convincing; piling on justification for a simple one makes it look more complicated than it is.

## Fixing flaky tests

Fix a flaky test. Never rerun it until it passes: a load-dependent flake
rarely recurs on demand, and a pass proves nothing.

- Save the first failure's output and artifacts before running anything
  else. They may be the only record of the race.
- Form a hypothesis about the race and test it. Add printouts, and force the
  suspect timing with an injected delay or state, until the failure
  reproduces every time. Running many copies at once adds the load that
  brings a race out.
- A flake can be a real bug the test caught under load. Decide which before
  changing the test.
- Fix the cause, and check that the fix passes with the forced timing still
  in. Then take the instrumentation out.
- Make tests deterministic. A test waits on a signal from the code, never a
  fixed sleep; when the code gives none, add one, through a small test-only
  shim if needed. A check that something is absent first waits for a
  positive sign that the work ran.

More in Grawlix's
[testing doc](https://github.com/jkugelman/grawlix/blob/main/docs/testing.md),
under "Debugging a flake".

## Don't create backup refs or commits

Before rewriting history — amend, rebase, squash, reset, force-push — don't create a backup branch, tag, or checkpoint commit "just in case." The reflog already preserves the old commits and is sufficient for resurrecting them when something goes wrong, so a backup ref adds nothing but clutter I have to notice and delete. Just do the rewrite. If you do create one anyway, clean it up yourself as part of the same task rather than leaving it behind or handing me the delete command.

## Don't optimize for less churn

When choosing between approaches, weigh only what produces the best code — never prefer an option because it touches fewer lines or is less work. Tedious, wide-reaching changes are fine. Existing patterns in a codebase are not load-bearing by default: question the architecture and redo existing systems when it makes the whole more elegant. Surface the better design even when it's the larger change.

## Prefer CLAUDE.md over memories — unless I ask for a memory

When *you* would reach for the file-based memory to record a rule or preference, prefer a CLAUDE.md instead: the project's checked-in `CLAUDE.md` for anything project-relevant or worth sharing with collaborators, this global file for cross-project personal preferences. Memories aren't version controlled and don't transfer to a new machine; CLAUDE.md files do — the project one through its repo, this one through my dotfiles.

**When I explicitly ask for a memory, write a memory.** Don't reroute it into a CLAUDE.md, and don't relitigate the choice first — the preference above governs your own unprompted judgment calls, it isn't a veto over a direct request. Machine-local facts earn a memory under the default too: a local checkout path or anything true only of this machine would be wrong on the next machine, which is exactly what a CLAUDE.md would carry there.

## Syntax-checking JavaScript

A hook syntax-checks every `.js`, `.mjs`, `.cjs`, `.html` and `.htm` file after an Edit or Write and reports any errors. For anything else — a file changed through Bash, or JS on stdin — run:

```
node ~/.claude/scripts/check-syntax.js <file>
```

It is pre-approved in `~/.claude/settings.json`, so it runs without a permission prompt. Use it instead of ad-hoc `node -e "..."` one-liners, which prompt every time.

## Planning docs

A plan written to think through imminent work — one you'll implement right away and then discard — is ephemeral: write it to `/tmp`, not into the repo, and don't commit it. Only a plan that stays useful in version control for a while, and isn't about to be implemented, belongs in the repo.

For a substantial rearchitecture whose feasibility is hard to judge up front, write the plan as a standalone doc and have an independent agent vet it before writing any code. Structure it so a reviewer can check the reasoning: load-bearing claims carry `file:line` anchors, validated claims stay separate from uncertain ones, and it closes with a list of what to verify during implementation.

## Don't warn me that `/tmp` files are ephemeral

I know files written to `/tmp` can be deleted at any time — it's why I send things there. Don't caveat, warn, or hedge about that when writing to `/tmp`; just write the file.

## Finding a commit's CI runs with `gh`

`gh run list --commit` takes the full 40-character SHA: `gh run list --commit "$(git rev-parse <sha>)"`.

One push can start several workflows (in Grawlix, *Test and deploy* and *Docs*). Pick the run by `workflowName` rather than taking `.[0]`, or you may watch the wrong one.

## Previewing Markdown

`gh markdown-preview --markdown-mode <file>` serves a live preview rendered by GitHub's API at `localhost:3333`, the way GitHub shows a file.

## Stacked PRs

When a change has parts a reviewer can take one at a time, such as a refactor and the feature built on it, open one PR per part as a stack: each PR's base is the branch of the PR below it. GitHub supports stacks natively, and the `gh stack` extension (`github/gh-stack`) manages them.

- To write the titles and descriptions yourself, open each PR with `gh pr create --draft --base <branch below>`, then join them with `gh stack link <bottom> … <top>`. It takes branches, PR numbers or URLs, bottom first, and opens a PR for any branch that has none.
- `gh stack init <branches…>` tracks existing branches as a local stack, and `gh stack submit --auto` pushes them and opens draft PRs with generated titles. `view`, `rebase`, `sync` and `push` manage a tracked stack.

Splitting a pushed PR into a stack resets its branch, which takes a force-push. Ask me before force-pushing.

# The dotfiles repo

`$HOME` is the work tree of a bare Git repo at `~/.dotfiles`, published at `github.com/jkugelman/dotfiles`. Use the `dotfiles` function for Git there; plain `git` doesn't work. Before real work on my config, invoke the `dotfiles` skill.

Edit `$HOME` in place, never in a worktree. Background jobs that isolate by default should skip the attempt.
