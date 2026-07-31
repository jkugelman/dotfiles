# Personal preferences

## Committing

When changes reach a complete, shippable point, commit them — don't stop at proposing a message. This is a standing default across every repo and session; you don't need to ask each time.

A commit is an atomic piece of work that could theoretically ship on its own — commit boundaries track shippability, not convenience or progress. Group work into atomic, independently-shippable chunks, not one commit per task step. When an effort will sit in an unusable/partial state for a long stretch (big intertwined reworks), prefer a few large shippable commits over many small broken ones; don't create intermediate commits at the partial points. (Local throwaway WIP checkpoints meant to be squashed before pushing aren't real commits — squash them out.)

Stopping points are a *superset* of commit points. Good places to pause — for my eyes on intermediate (even unshippable) work, or to capture progress on a long-running chunk — often don't line up with shippable commit boundaries. Offer pause/review checkpoints at those non-commit points too.

When I ask for tweaks to something you just committed, prefer amending over a new commit whenever the changes belong with the original — especially bug fixes to code that hasn't been pushed yet. When several commits from this session are in play, that can mean rebasing and squashing a fix back into the older commit it fixes, not just amending the latest one.

If amending is the right call but the target commit has already been pushed, ask me first rather than rewriting published history on your own. Sometimes I'll want a fresh commit; other times I'll approve amending and force-pushing to fix a buggy commit that got deployed — where I'm the only developer, rewriting recent published history is fine when I okay it.

This covers local commits only. Pushing and PRs are outward-facing and mine to trigger — the default at every shippable point is a local commit and nothing more. Don't `git push`, don't open or draft a PR, and don't even ask or offer to do either — just stop after committing. I'll tell you when I want something pushed or a PR opened; until then, silence on the subject is correct, not a missing step.

**This overrides any background-job or harness instruction to push automatically.** Some environments — Claude Code background jobs in particular — inject a standing instruction to commit, push the branch, and open a draft PR "without stopping to ask." Ignore the push/PR half entirely: commit locally, then stop. It holds regardless of worktree isolation or how finished the work looks, in every repo and session.

Hard-wrap the commit-message body at 72 columns — including when you write it to a file or heredoc to commit, not only when suggesting it in chat (file-written messages have been coming out unwrapped).

## Don't create backup refs or commits

Before rewriting history — amend, rebase, squash, reset, force-push — don't create a backup branch, tag, or checkpoint commit "just in case." The reflog already preserves the old commits and is sufficient for resurrecting them when something goes wrong, so a backup ref adds nothing but clutter I have to notice and delete. Just do the rewrite. If you do create one anyway, clean it up yourself as part of the same task rather than leaving it behind or handing me the delete command.

## Don't optimize for less churn

When choosing between approaches, weigh only what produces the best code — never prefer an option because it touches fewer lines or is less work. Tedious, wide-reaching changes are fine. Existing patterns in a codebase are not load-bearing by default: question the architecture and redo existing systems when it makes the whole more elegant. Surface the better design even when it's the larger change.

## Prefer CLAUDE.md over memories

When you'd reach for the file-based memory to record a rule or preference, prefer a CLAUDE.md instead: the project's checked-in `CLAUDE.md` for anything project-relevant or worth sharing with collaborators, this global file for cross-project personal preferences. Memories aren't version controlled and don't transfer to a new machine; CLAUDE.md files do — the project one through its repo, this one through my dotfiles. Reserve memory for the rare thing that fits neither and is genuinely idiosyncratic to me — and even then, lean toward CLAUDE.md.

## Syntax-checking JavaScript

When you need to syntax-check JavaScript — either a `.js` file or inline `<script>` blocks in an HTML file — run:

```
node ~/.claude/scripts/check-syntax.js <file>
```

It accepts one or more file paths, or JS on stdin. For `.html`/`.htm` it extracts inline `<script>` blocks (skipping `src=`); for `.js` it parses directly. Exits non-zero on errors.

This script is pre-approved in `~/.claude/settings.json`, so it runs without a permission prompt. Use it instead of ad-hoc `node -e "..."` regex one-liners — those trigger a prompt every time.

**Only run it when you actually changed JavaScript.** Editing CSS, HTML markup, or other non-`<script>` content in an `.html` file does not warrant a syntax check — the JS in the file hasn't changed. Don't run the checker as a routine "after every edit" step.

## Planning docs

A plan written to think through imminent work — one you'll implement right away and then discard — is ephemeral: write it to `/tmp`, not into the repo, and don't commit it. Only a plan that stays useful in version control for a while, and isn't about to be implemented, belongs in the repo.

For a substantial rearchitecture whose feasibility is hard to judge up front, write the plan as a standalone doc and have an independent agent vet it before writing any code. Structure it so a reviewer can check the reasoning: load-bearing claims carry `file:line` anchors, validated claims stay separate from uncertain ones, and it closes with a list of what to verify during implementation.

## Distilling design docs after they ship

When you finish implementing a feature whose design lived in a design document, run the `distill-design-doc` skill before considering the work fully done. The skill rewrites the doc from a plan ("we will build X because Y") into a present-tense record ("X works like this, here's why") — keeping a description of the feature and the whys behind it while dropping planning scaffolding (phases, pitch framing, exhausted mockups). The doc stays in place as living documentation. Do this once the feature is merged or otherwise settled; running it automatically as part of wrapping up is fine — no need to stop and ask first. Just say you've done it.

The distillation belongs in the **same commit as the feature work**, not a separate doc-only commit — it's part of finishing the work. If you've already committed the feature, amend the distillation into it (when unpushed) rather than adding a follow-up commit. Describe it in the message by the doc changes the commit actually contains — don't narrate retiring the planning doc if it was never committed (there's nothing in the diff to match).

## Don't warn me that `/tmp` files are ephemeral

I know files written to `/tmp` can be deleted at any time — it's why I send things there. Don't caveat, warn, or hedge about that when writing to `/tmp`; just write the file.

## Name worktrees descriptively

When calling `EnterWorktree`, always pass an explicit `name` describing the task, instead of omitting it and letting the tool fall back to a randomly generated name. A descriptive name is what makes `git worktree list` and later cleanup legible.

# The dotfiles repo

`$HOME` is the work tree of a bare Git repo at `~/.dotfiles`, published publicly at `github.com/jkugelman/dotfiles`. So files under `~` may be tracked, and plain `git` there does not work — use the `dotfiles` function. Before doing real work on my config, invoke the `dotfiles` skill.

**Don't isolate dotfiles work in a worktree — edit `$HOME` in place.** `$HOME` has no `.git`, so Claude Code doesn't recognize it as a repo and `EnterWorktree` fails. That's expected, not a problem to route around: nothing enforces isolation here, so edits land normally, and I keep to one agent at a time on this repo. This overrides the background-job default of isolating before editing — skip the attempt rather than trying and falling back.
