---
name: wt
description: Lifecycle helper for git worktrees — works with any worktree regardless of where it lives or how its branch is named (created by `git worktree add`, a tool like worktrunk, or Claude Code's EnterWorktree). Operates on the worktree your cwd is in, or one named/pathed as an argument. Subcommands — `/wt merge [--into <branch>]`: rebase the worktree's branch onto the branch it came from (what the session knows, checked against the branch it forked from, asking when they disagree; `--into` overrides), resolve any conflicts, fast-forward that branch (no merge commit), then tear the worktree down with the same safety-checked cleanup as `/wt delete`. `/wt delete`: that teardown on its own — remove the worktree + delete the branch, confirming first if it's unmerged or dirty. Everything is read from git; nothing about location or naming is assumed. Local-only — it never pushes.
---

# wt — git worktree lifecycle

Merge or tear down a git worktree. Works with **any** worktree — one you made with `git worktree add`, one from a tool like worktrunk, or one Claude Code's `EnterWorktree` created — because it reads everything (location, branch, the branch to merge into, where that branch is checked out) from git rather than assuming a layout.

`/wt merge` is the merge steps followed by exactly the same teardown as `/wt delete`; the removal logic lives in one shared section (*Removing the worktree + branch*) that both use.

## Resolve the target worktree

The target is a **linked worktree** — never the primary working tree, which can't be removed. The source of truth is `git worktree list --porcelain`.

- **No argument** → the worktree your cwd is in: `WT=$(git rev-parse --show-toplevel)`. It must be a linked worktree; if it isn't (you're in the main tree, or not in a worktree at all), stop and ask for a name or path.
- **An argument** (other than `--into <branch>`, which names the target branch) → match it against `git worktree list`: by exact path, by the worktree directory's basename, or by branch short-name. Unique match wins; if it's ambiguous, list the candidates and ask; if nothing matches, say so.

Then read the rest from git:

```
BR=$(git -C "$WT" symbolic-ref --quiet --short HEAD)   # the worktree's branch; empty if detached HEAD
TIP=$(git -C "$WT" rev-parse HEAD)                      # the worktree's commit, branch or not
SAFE=$(git worktree list --porcelain | sed -n 's/^worktree //p' | head -n1)   # primary worktree: a safe cwd for repo-level ops
```

**Resolve these silently — they're internal bookkeeping.** Don't echo or narrate `$WT` / `$BR` / `$TIP` / `$TARGET` / `$SAFE` (or `$TARGET_WT`, resolved in `/wt merge`) back to the user — no "Variables: WT = …, BR = …" preamble. Surface only the outcome: each subcommand's *Report* step, plus any conflict or confirmation that genuinely needs the user. Where a value *does* surface — a *Report* line, or the one-line **description** on each Bash call this skill runs — write the **resolved value** (the actual branch name, target-branch name, path), never the literal `$BR`/`$TARGET`/`$WT` token; the placeholders in this doc stand in for their values. Describe the fast-forward step as e.g. `Fast-forward main onto add-widget`, not `Merged "$BR"` — a description that echoes the raw token instead of the branch name is the exact leak to avoid.

### Resolve the target branch

`$TARGET` is the branch the worktree's work lands in (`/wt merge`) or is checked against (`/wt delete`): the branch it came from, which isn't always the repo's default — a worktree cut from a feature branch merges back into that feature branch. Git doesn't reliably record it (`EnterWorktree` branches record `Created from origin/main` or `Created from HEAD`, even when the worktree was then reset onto a feature branch), so the agent running this skill decides, git checks the decision, and the user settles any doubt:

1. **`--into <branch>`** in the arguments → that local branch. It must exist (`git show-ref --verify --quiet "refs/heads/<branch>"`); if not, say so and stop.
2. **What the session knows.** The agent often knows where the worktree came from: it created the worktree and reset or rebased it onto a branch, a CLAUDE.md names the branch the work belongs on, or the user said. Use that branch.
3. **The nearest fork point.** Rank every other local branch by how many of `$BR`'s commits it lacks — the commits a rebase onto it would replay. The branch `$BR` forked from lacks only the worktree's own work, so it ranks first:
   ```
   git for-each-ref --format='%(refname:short)' refs/heads/ | while read -r b; do
     [ "$b" = "$BR" ] && continue
     git merge-base "$b" "$BR" >/dev/null 2>&1 || continue   # no shared history
     printf '%s %s\n' "$(git rev-list --count "$b..$BR")" "$b"
   done | sort -n | head -n5
   ```
   Branches checked out in other linked worktrees are usually siblings cut from the same base, not the source; on a tie they rank below the rest.

Go ahead without asking only when 2 and 3 agree, or when 2 says nothing and 3 has a clear winner. Ask the user which branch to use (AskUserQuestion, listing the top candidates with their counts) when 2 and 3 disagree, when 3 ties, or when no candidate shares history with `$BR`. A wrong target is costly — a rebase onto `main` from a feature-branch worktree replays the whole feature branch and lands it on `main` — so a question is cheap by comparison.

State the chosen target and why (`--into`, the session's knowledge, or the fork point) in one line before running anything.

Guards: `$WT` is a linked worktree (not `$SAFE`/the primary). If `$BR` is set it must not be `$TARGET`. **Detached HEAD** (`$BR` empty): `merge` can't run — there's no branch to fast-forward from or delete — so say so and stop; `delete` still works (it removes the worktree, with the merged check done against `$TIP`).

Run every worktree-removing / branch-deleting command from `$SAFE` (or any directory outside `$WT`), **never** from inside `$WT` — removing a worktree from within it fails and strands your cwd (`cd "$SAFE"` afterward if the shell was inside it).

## /wt merge — rebase onto the target branch, fast-forward, then tear down

Bring the worktree's commits into the target branch with **no merge commit**, then tear the worktree down (the same cleanup as `/wt delete`).

Find where the target branch is checked out — it needn't be the primary worktree, and might not be checked out at all:

```
TARGET_WT=$(git worktree list --porcelain | while read -r key val; do
  [ "$key" = worktree ] && wtp=$val
  [ "$key" = branch ] && [ "$val" = "refs/heads/$TARGET" ] && { printf '%s\n' "$wtp"; break; }
done)
```

**Preconditions** — stop clearly if any fail:
1. `$WT` has no uncommitted changes to **tracked** files: `git -C "$WT" status --porcelain --untracked-files=no` empty (else commit/stash first). Untracked files don't block the rebase — it carries them along, and the teardown confirms before discarding any.
2. `$BR` set and `!= $TARGET`.
3. The commits the rebase would replay, `git log --oneline "$TARGET..$BR"`, are the worktree's own work. Dozens of commits from a worktree that added two means `$TARGET` is wrong — stop and ask, whatever picked it.

The worktree is the only working tree checked proactively. There's deliberately **no** cleanliness gate on the target-branch checkout — the fast-forward in step 3 polices itself, and pre-checking it is both redundant and too strict (it would trip over harmless untracked files like a sibling skill awaiting this merge's gitignore change).

**Concurrent merges race on the target branch — detect and retry.** Two `/wt merge`s at once (different sessions, same repo) both rebase and then both try to advance `$TARGET`. That one ref update is the only contended resource, and git makes it atomic: `merge --ff-only` refuses anything that isn't a true fast-forward, and the bare-ref path below is a *compare-and-swap* (`update-ref` with an expected old value), never a force-move — so a lost race **refuses rather than clobbers**. Step 2 attempts the fast-forward and, on failure, checks whether it *got beaten* (another merge advanced `$TARGET` out from under it); if so it re-runs the whole process — rebase onto the now-current tip, then fast-forward again — until it lands.

**Steps:**
1. Rebase onto the target branch, in the worktree:
   ```
   git -C "$WT" rebase "$TARGET"
   ```
   Conflicts → list `git -C "$WT" diff --name-only --diff-filter=U`; resolve in the worktree (`git -C "$WT" add <files>`, `git -C "$WT" rebase --continue`); surface non-trivial conflicts and wait; bail with `git -C "$WT" rebase --abort` (restores the pre-rebase state).
2. **If the session lives in `$WT`, detach the harness now — before the fast-forward, not at teardown.** A worktree-isolated Claude Code session refuses *any* `git -C` that targets a path outside its own worktree ("this command redirects git to the shared checkout via `-C`"), and step 3 targets `$TARGET_WT`/`$SAFE` — so while pinned, the fast-forward cannot run at all. Detach with the **`ExitWorktree` tool, `action: "keep"`** (see *Removing the worktree + branch* step 3 for why `keep` and when to skip it); it leaves the worktree and branch fully intact on disk, so nothing about the merge changes — only the session's cwd. Do it **after** the rebase, which runs inside `$WT` and is fine while pinned. Once detached, `git -C "$WT" …` works too, so the step-3 retry loop still rebases normally.
3. Fast-forward the target branch to `$BR`. After the rebase `$BR` is a strict descendant of `$TARGET`, so this can't create a merge commit:
   - Checked out somewhere → advance that working tree there:
     ```
     git -C "$TARGET_WT" merge --ff-only "$BR"
     ```
   - Checked out nowhere (`$TARGET_WT` empty) → move the ref with a compare-and-swap:
     ```
     CUR=$(git -C "$SAFE" rev-parse "refs/heads/$TARGET")
     git -C "$SAFE" update-ref "refs/heads/$TARGET" "$BR" "$CUR"
     ```
   Both self-guard against a concurrent merge: `merge --ff-only` refuses anything but a true fast-forward (it ignores untracked files, failing only on a real conflict), and the CAS `update-ref` refuses if `$TARGET` moved since `$CUR` was read. **Never `git branch -f`** — it force-moves the ref and would silently discard a commit another session just landed. Success (including a clean no-op — "Already up to date" — when `$BR` has no commits beyond `$TARGET`) → tear down.

   On **failure**, find out whether you got **beaten** — another merge advanced `$TARGET` out from under you:
   ```
   git -C "$WT" merge-base --is-ancestor "$TARGET" "$BR"
   ```
   - **Non-zero → beaten.** `$TARGET` now points onto a commit that isn't in `$BR`'s history. Go back to **step 1** and redo the rebase: `git -C "$WT" rebase "$TARGET"` picks up the now-current tip (re-resolve any fresh conflicts against the just-landed work, as in step 1), then re-attempt this fast-forward. Loop until it lands. Step 2 is already done and isn't repeated — detaching is idempotent, and a second `ExitWorktree` would be a no-op anyway.
   - **Zero → genuine error, not a race.** `$BR` still descends from the current `$TARGET`, so the failure is real: the target-branch checkout has conflicting local changes (or, rarely, two sessions hit its index at the same instant). Surface it and stop — the rebase is already done, so re-running just retries the fast-forward, which also clears a transient collision.
4. **Tear down** the worktree + branch — run *Removing the worktree + branch* below. Its detach step is already satisfied by step 2, so it goes straight to the removal. After the fast-forward the branch is merged and the worktree is normally clean, so it removes without prompting; if conflict resolution left untracked files behind, the dirty check there catches them and confirms first.
5. **Report:** `$BR` fast-forwarded onto `$TARGET` (N commits), worktree + branch removed. `$TARGET` is now **ahead of origin — do not push** (the user pushes when ready).

## /wt delete — tear down a worktree, confirming if unmerged

Remove a worktree + its branch. This is just the shared teardown below, plus a report.

1. **Tear down** — run *Removing the worktree + branch* below.
2. **Report** what was removed and whether it had been merged. `cd "$SAFE"` if the shell was inside it.

## Removing the worktree + branch

The shared teardown used by both subcommands — the whole of `/wt delete`, and the final step of `/wt merge`. Given the resolved `$WT`, `$BR`, `$TIP`, `$TARGET`, `$SAFE`:

1. **Assess:**
   - **Merged?** `git -C "$SAFE" merge-base --is-ancestor "$TIP" "$TARGET"` (exit 0 = the worktree's commit is already in the target branch — always true right after `/wt merge`'s fast-forward; works whether or not it's on a branch).
   - **Dirty?** `git -C "$WT" status --porcelain` non-empty (uncommitted or untracked files — e.g. conflict-resolution leftovers).
2. If **not** (merged AND clean) → removing would discard commits and/or files. Confirm (AskUserQuestion), naming exactly what's lost (N unmerged commits, and/or uncommitted changes). Proceed only on explicit confirmation; otherwise stop and change nothing.
3. **If the session lives in `$WT`, detach the harness first.** (`/wt merge` has already done this at its own step 2, because the fast-forward can't run while pinned; re-running here is an `ExitWorktree` no-op, so this step is really `/wt delete`'s.) When the current Claude Code session is working *inside* `$WT` — an `EnterWorktree`-made worktree; the usual no-argument `/wt merge`/`/wt delete`, or an argument naming your own worktree — the harness pins the session's cwd inside `$WT` and keeps resetting it back there, so the raw `git worktree remove` in step 4 would strand it. Being pinned also blocks the `git -C "$SAFE"` removals in step 4 outright, the same way it blocks `/wt merge`'s fast-forward. Detach first with the **`ExitWorktree` tool, `action: "keep"`**: `keep` leaves the worktree *and* branch on disk untouched (step 4 does the actual removal) and restores the session's cwd to outside `$WT`. Because it's `keep`, not `remove`, it trips **none** of `ExitWorktree`'s guards — no spurious "N commits will be discarded" refusal for work `/wt merge` already fast-forwarded onto `$TARGET`.
   - **Only when it's the session's own worktree.** If `$WT` is a *different* worktree you aren't sitting in (named as an argument from elsewhere), **skip** this step — never `ExitWorktree` a worktree you aren't targeting, since it acts on the session's worktree, not `$WT`. And if `$WT` isn't an `EnterWorktree` session worktree at all, `ExitWorktree` is a documented no-op — harmless; proceed to step 4 either way.
4. **Remove** — unlock first (a harmless no-op if it wasn't locked), run from `$SAFE`, never from inside `$WT`:
   ```
   git -C "$SAFE" worktree unlock "$WT" 2>/dev/null || true
   git -C "$SAFE" worktree remove "$WT"          # add --force if dirty or unmerged (once confirmed)
   [ -n "$BR" ] && git -C "$SAFE" branch -d "$BR"    # -D if unmerged (once confirmed); skip when detached
   ```

**On `ExitWorktree`'s guards.** The *removal* is done with git (step 4), never `ExitWorktree action: "remove"`, so this skill's own merged/dirty check (steps 1–2) stays the single guard across every worktree type. `ExitWorktree`'s `remove` guard measures "unmerged" against the branch's *original* base (typically origin's default branch), so after a local fast-forward it still counts the now-merged commits as discardable and refuses without `discard_changes: true` — a guard that's simply wrong for `/wt`, which intentionally lands work on the **local** target branch and never pushes. `keep` sidesteps it. If you ever must remove *through* `ExitWorktree` (keep is somehow unavailable), passing `discard_changes: true` is authorized — but only **after** step 1 shows merged or step 2's confirmation was given, never before.

## Notes

- Works with any git worktree — `git worktree add`, worktrunk, `EnterWorktree`, whatever put it there. Nothing assumes where worktrees live or how branches are named; it's all read from `git worktree list` and `git`.
- `git worktree unlock` is a harmless no-op on an unlocked worktree, so the teardown doesn't care whether it was locked (`EnterWorktree` locks its own; most worktrees aren't).
- Operating on the worktree the **current Claude Code session lives in** detaches the harness with `ExitWorktree action: "keep"` first, because a worktree-isolated session both pins its cwd inside `$WT` and refuses any `git -C` aimed outside it. `/wt merge` therefore detaches right after the rebase (step 2) rather than at teardown — its fast-forward targets the target branch's checkout and is blocked while pinned; `/wt delete` detaches in the teardown, before the git removal. `keep` carries no discard guard, so a `/wt merge` whose commits are already fast-forwarded onto the local target branch tears down without a false "N commits will be discarded" prompt.
- **Local-only. Never push, never touch origin.** `/wt merge` leaves the target branch ahead of origin for the user to push when ready.
- **Concurrent `/wt merge`s rely on git's atomic ref update.** `merge --ff-only` and the CAS `update-ref` both *refuse* a stale fast-forward rather than clobber, so a race can never lose commits; the bare-ref path uses `update-ref` with an expected old value, never `git branch -f` (a force-move that could). The loser detects it got beaten (step 2's `is-ancestor` check) and re-runs the whole process — rebase onto the now-current target, then fast-forward — until it lands. `/wt delete` doesn't race — it touches only its own worktree.
- Always read the branch from git and handle detached HEAD; run removals from `$SAFE`, never from inside the target.
- The worktree-list parsing avoids awk `$0` and positional `$1`/`$2`: when the skill is invoked with an argument (`/wt merge <name>`), the launcher substitutes those placeholders with the argument tokens, which would corrupt any snippet using them. Named `$VARS` are untouched.
