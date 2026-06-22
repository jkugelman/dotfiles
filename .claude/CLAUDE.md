# Personal preferences

## Don't commit unless I authorize it

Default to not running `git commit`. Finishing a task, passing tests, or reaching a clean stopping point is not an invitation to commit — leave the changes staged or unstaged and let me decide. Suggesting a commit message in chat is fine.

I do authorize committing from time to time, though — sometimes for a single commit, sometimes as a standing grant for a whole effort or session ("commit as you go on this branch"). When I've given a standing authorization, honor it for that effort without re-asking each time; when it's unclear whether a grant still applies (e.g. a new session), ask before committing rather than assuming.

Hard-wrap the commit-message body at 72 columns — including when you write it to a file or heredoc to commit, not only when suggesting it in chat (file-written messages have been coming out unwrapped).

## Don't optimize for less churn

When choosing between approaches, weigh only what produces the best code — never prefer an option because it touches fewer lines or is less work. Tedious, wide-reaching changes are fine. Existing patterns in a codebase are not load-bearing by default: question the architecture and redo existing systems when it makes the whole more elegant. Surface the better design even when it's the larger change.

## Prefer CLAUDE.md over memories

When you'd reach for the file-based memory to record a rule or preference, prefer a CLAUDE.md instead: the project's checked-in `CLAUDE.md` for anything project-relevant or worth sharing with collaborators, this global file for cross-project personal preferences. Memories aren't version controlled and don't transfer to a new machine; CLAUDE.md files do — the project one through its repo, this one through my dotfiles. Reserve memory for the rare thing that fits neither and is genuinely idiosyncratic to me — and even then, lean toward CLAUDE.md.

## Syntax-checking JavaScript

When you need to syntax-check JavaScript — either a `.js` file or inline `<script>` blocks in an HTML file — run:

```
node /home/jkugelman/.claude/scripts/check-syntax.js <file>
```

It accepts one or more file paths, or JS on stdin. For `.html`/`.htm` it extracts inline `<script>` blocks (skipping `src=`); for `.js` it parses directly. Exits non-zero on errors.

This script is pre-approved in `~/.claude/settings.json`, so it runs without a permission prompt. Use it instead of ad-hoc `node -e "..."` regex one-liners — those trigger a prompt every time.

**Only run it when you actually changed JavaScript.** Editing CSS, HTML markup, or other non-`<script>` content in an `.html` file does not warrant a syntax check — the JS in the file hasn't changed. Don't run the checker as a routine "after every edit" step.

## Distilling design docs after they ship

When you finish implementing a feature whose design lived in a design document, run the `distill-design-doc` skill before considering the work fully done. The skill rewrites the doc from a plan ("we will build X because Y") into a present-tense record ("X works like this, here's why") — keeping a description of the feature and the whys behind it while dropping planning scaffolding (phases, pitch framing, exhausted mockups). The doc stays in place as living documentation. Do this once the feature is merged or otherwise settled; running it automatically as part of wrapping up is fine — no need to stop and ask first. Just say you've done it.

The distillation belongs in the **same commit as the feature work**, not a separate doc-only commit — it's part of finishing the work. If you've already committed the feature, amend the distillation into it (when unpushed) rather than adding a follow-up commit. Describe it in the message by the doc changes the commit actually contains — don't narrate retiring the planning doc if it was never committed (there's nothing in the diff to match).
