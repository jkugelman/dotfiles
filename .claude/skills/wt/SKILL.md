---
name: wt
description: Lifecycle helper for git worktrees — works with any worktree regardless of where it lives or how its branch is named (created by `git worktree add`, a tool like worktrunk, or Claude Code's EnterWorktree). Operates on the worktree your cwd is in, or one named/pathed as an argument. Subcommands — `/wt merge`: rebase the worktree's branch onto the default branch, resolve any conflicts, fast-forward the default branch (no merge commit), then tear the worktree down with the same safety-checked cleanup as `/wt delete`. `/wt delete`: that teardown on its own — remove the worktree + delete the branch, confirming first if it's unmerged or dirty. Everything is read from git; nothing about location or naming is assumed. Local-only — it never pushes.
---

# wt — git worktree lifecycle

Merge or tear down a git worktree. Works with **any** worktree — one you made with `git worktree add`, one from a tool like worktrunk, or one Claude Code's `EnterWorktree` created — because it reads everything (location, branch, the default branch, where the default branch is checked out) from git rather than assuming a layout.

`/wt merge` is the merge steps followed by exactly the same teardown as `/wt delete`; the removal logic lives in one shared section (*Removing the worktree + branch*) that both use.

## Resolve the target worktree

The target is a **linked worktree** — never the primary working tree, which can't be removed. The source of truth is `git worktree list --porcelain`.

- **No argument** → the worktree your cwd is in: `WT=$(git rev-parse --show-toplevel)`. It must be a linked worktree; if it isn't (you're in the main tree, or not in a worktree at all), stop and ask for a name or path.
- **An argument** → match it against `git worktree list`: by exact path, by the worktree directory's basename, or by branch short-name. Unique match wins; if it's ambiguous, list the candidates and ask; if nothing matches, say so.

Then read the rest from git:

```
BR=$(git -C "$WT" symbolic-ref --quiet --short HEAD)   # the worktree's branch; empty if detached HEAD
TIP=$(git -C "$WT" rev-parse HEAD)                      # the worktree's commit, branch or not
DEFAULT=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')
DEFAULT=${DEFAULT:-$(git show-ref --verify --quiet refs/heads/main && echo main || echo master)}
SAFE=$(git worktree list --porcelain | sed -n 's/^worktree //p' | head -n1)   # primary worktree: a safe cwd for repo-level ops
```

**Resolve these silently — they're internal bookkeeping.** Don't echo or narrate `$WT` / `$BR` / `$TIP` / `$DEFAULT` / `$SAFE` (or `$DEFAULT_WT`, resolved in `/wt merge`) back to the user — no "Variables: WT = …, BR = …" preamble. Surface only the outcome: each subcommand's *Report* step, plus any conflict or confirmation that genuinely needs the user. Where a value *does* surface — a *Report* line, or the one-line **description** on each Bash call this skill runs — write the **resolved value** (the actual branch name, default-branch name, path), never the literal `$BR`/`$DEFAULT`/`$WT` token; the placeholders in this doc stand in for their values. Describe the fast-forward step as e.g. `Fast-forward main onto add-widget`, not `Merged "$BR"` — a description that echoes the raw token instead of the branch name is the exact leak to avoid.

Guards: `$WT` is a linked worktree (not `$SAFE`/the primary). If `$BR` is set it must not be `$DEFAULT`. **Detached HEAD** (`$BR` empty): `merge` can't run — there's no branch to fast-forward from or delete — so say so and stop; `delete` still works (it removes the worktree, with the merged check done against `$TIP`).

Run every worktree-removing / branch-deleting command from `$SAFE` (or any directory outside `$WT`), **never** from inside `$WT` — removing a worktree from within it fails and strands your cwd (`cd "$SAFE"` afterward if the shell was inside it).

## /wt merge — rebase onto the default branch, fast-forward, then tear down

Bring the worktree's commits into the default branch with **no merge commit**, then tear the worktree down (the same cleanup as `/wt delete`).

Find where the default branch is checked out — it needn't be the primary worktree, and might not be checked out at all:

```
DEFAULT_WT=$(git worktree list --porcelain | while read -r key val; do
  [ "$key" = worktree ] && wtp=$val
  [ "$key" = branch ] && [ "$val" = "refs/heads/$DEFAULT" ] && { printf '%s\n' "$wtp"; break; }
done)
```

**Preconditions** — stop clearly if any fail:
1. `$WT` has no uncommitted changes to **tracked** files: `git -C "$WT" status --porcelain --untracked-files=no` empty (else commit/stash first). Untracked files don't block the rebase — it carries them along, and the teardown confirms before discarding any.
2. `$BR` set and `!= $DEFAULT`.

The worktree is the only working tree checked proactively. There's deliberately **no** cleanliness gate on the default-branch checkout — the fast-forward in step 2 polices itself, and pre-checking it is both redundant and too strict (it would trip over harmless untracked files like a sibling skill awaiting this merge's gitignore change).

**Concurrent merges race on the default branch — detect and retry.** Two `/wt merge`s at once (different sessions, same repo) both rebase and then both try to advance `$DEFAULT`. That one ref update is the only contended resource, and git makes it atomic: `merge --ff-only` refuses anything that isn't a true fast-forward, and the bare-ref path below is a *compare-and-swap* (`update-ref` with an expected old value), never a force-move — so a lost race **refuses rather than clobbers**. Step 2 attempts the fast-forward and, on failure, checks whether it *got beaten* (another merge advanced `$DEFAULT` out from under it); if so it re-runs the whole process — rebase onto the now-current tip, then fast-forward again — until it lands.

**Steps:**
1. Rebase onto the default branch, in the worktree:
   ```
   git -C "$WT" rebase "$DEFAULT"
   ```
   Conflicts → list `git -C "$WT" diff --name-only --diff-filter=U`; resolve in the worktree (`git -C "$WT" add <files>`, `git -C "$WT" rebase --continue`); surface non-trivial conflicts and wait; bail with `git -C "$WT" rebase --abort` (restores the pre-rebase state).
2. Fast-forward the default branch to `$BR`. After the rebase `$BR` is a strict descendant of `$DEFAULT`, so this can't create a merge commit:
   - Checked out somewhere → advance that working tree there:
     ```
     git -C "$DEFAULT_WT" merge --ff-only "$BR"
     ```
   - Checked out nowhere (`$DEFAULT_WT` empty) → move the ref with a compare-and-swap:
     ```
     CUR=$(git -C "$SAFE" rev-parse "refs/heads/$DEFAULT")
     git -C "$SAFE" update-ref "refs/heads/$DEFAULT" "$BR" "$CUR"
     ```
   Both self-guard against a concurrent merge: `merge --ff-only` refuses anything but a true fast-forward (it ignores untracked files, failing only on a real conflict), and the CAS `update-ref` refuses if `$DEFAULT` moved since `$CUR` was read. **Never `git branch -f`** — it force-moves the ref and would silently discard a commit another session just landed. Success (including a clean no-op — "Already up to date" — when `$BR` has no commits beyond `$DEFAULT`) → tear down.

   On **failure**, find out whether you got **beaten** — another merge advanced `$DEFAULT` out from under you:
   ```
   git -C "$WT" merge-base --is-ancestor "$DEFAULT" "$BR"
   ```
   - **Non-zero → beaten.** `$DEFAULT` now points onto a commit that isn't in `$BR`'s history. Go back to **step 1** and redo the whole thing: `git -C "$WT" rebase "$DEFAULT"` picks up the now-current tip (re-resolve any fresh conflicts against the just-landed work, as in step 1), then re-attempt this fast-forward. Loop until it lands.
   - **Zero → genuine error, not a race.** `$BR` still descends from the current `$DEFAULT`, so the failure is real: the default-branch checkout has conflicting local changes (or, rarely, two sessions hit its index at the same instant). Surface it and stop — the rebase is already done, so re-running just retries the fast-forward, which also clears a transient collision.
3. **Tear down** the worktree + branch — run *Removing the worktree + branch* below. After the fast-forward the branch is merged and the worktree is normally clean, so it removes without prompting; if conflict resolution left untracked files behind, the dirty check there catches them and confirms first.
4. **Report:** `$BR` fast-forwarded onto `$DEFAULT` (N commits), worktree + branch removed. `$DEFAULT` is now **ahead of origin — do not push** (the user pushes when ready).

## /wt delete — tear down a worktree, confirming if unmerged

Remove a worktree + its branch. This is just the shared teardown below, plus a report.

1. **Tear down** — run *Removing the worktree + branch* below.
2. **Report** what was removed and whether it had been merged. `cd "$SAFE"` if the shell was inside it.

## Removing the worktree + branch

The shared teardown used by both subcommands — the whole of `/wt delete`, and the final step of `/wt merge`. Given the resolved `$WT`, `$BR`, `$TIP`, `$DEFAULT`, `$SAFE`:

1. **Assess:**
   - **Merged?** `git -C "$SAFE" merge-base --is-ancestor "$TIP" "$DEFAULT"` (exit 0 = the worktree's commit is already in the default branch — always true right after `/wt merge`'s fast-forward; works whether or not it's on a branch).
   - **Dirty?** `git -C "$WT" status --porcelain` non-empty (uncommitted or untracked files — e.g. conflict-resolution leftovers).
2. If **not** (merged AND clean) → removing would discard commits and/or files. Confirm (AskUserQuestion), naming exactly what's lost (N unmerged commits, and/or uncommitted changes). Proceed only on explicit confirmation; otherwise stop and change nothing.
3. **If the session lives in `$WT`, detach the harness first.** When the current Claude Code session is working *inside* `$WT` — an `EnterWorktree`-made worktree; the usual no-argument `/wt merge`/`/wt delete`, or an argument naming your own worktree — the harness pins the session's cwd inside `$WT` and keeps resetting it back there, so the raw `git worktree remove` in step 4 would strand it. Detach first with the **`ExitWorktree` tool, `action: "keep"`**: `keep` leaves the worktree *and* branch on disk untouched (step 4 does the actual removal) and restores the session's cwd to outside `$WT`. Because it's `keep`, not `remove`, it trips **none** of `ExitWorktree`'s guards — no spurious "N commits will be discarded" refusal for work `/wt merge` already fast-forwarded onto `$DEFAULT`.
   - **Only when it's the session's own worktree.** If `$WT` is a *different* worktree you aren't sitting in (named as an argument from elsewhere), **skip** this step — never `ExitWorktree` a worktree you aren't targeting, since it acts on the session's worktree, not `$WT`. And if `$WT` isn't an `EnterWorktree` session worktree at all, `ExitWorktree` is a documented no-op — harmless; proceed to step 4 either way.
4. **Remove** — unlock first (a harmless no-op if it wasn't locked), run from `$SAFE`, never from inside `$WT`:
   ```
   git -C "$SAFE" worktree unlock "$WT" 2>/dev/null || true
   git -C "$SAFE" worktree remove "$WT"          # add --force if dirty or unmerged (once confirmed)
   [ -n "$BR" ] && git -C "$SAFE" branch -d "$BR"    # -D if unmerged (once confirmed); skip when detached
   ```

**On `ExitWorktree`'s guards.** The *removal* is done with git (step 4), never `ExitWorktree action: "remove"`, so this skill's own merged/dirty check (steps 1–2) stays the single guard across every worktree type. `ExitWorktree`'s `remove` guard measures "unmerged" against the branch's *original* base (typically `origin/$DEFAULT`), so after a local fast-forward it still counts the now-merged commits as discardable and refuses without `discard_changes: true` — a guard that's simply wrong for `/wt`, which intentionally lands work on the **local** default branch and never pushes. `keep` sidesteps it. If you ever must remove *through* `ExitWorktree` (keep is somehow unavailable), passing `discard_changes: true` is authorized — but only **after** step 1 shows merged or step 2's confirmation was given, never before.

## Notes

- Works with any git worktree — `git worktree add`, worktrunk, `EnterWorktree`, whatever put it there. Nothing assumes where worktrees live or how branches are named; it's all read from `git worktree list` and `git`.
- `git worktree unlock` is a harmless no-op on an unlocked worktree, so the teardown doesn't care whether it was locked (`EnterWorktree` locks its own; most worktrees aren't).
- Tearing down the worktree the **current Claude Code session lives in** detaches the harness with `ExitWorktree action: "keep"` before the git removal (see *Removing the worktree + branch*), because the harness pins the session's cwd inside it. `keep` carries no discard guard, so a `/wt merge` whose commits are already fast-forwarded onto the local default branch tears down without a false "N commits will be discarded" prompt.
- **Local-only. Never push, never touch origin.** `/wt merge` leaves the default branch ahead of origin for the user to push when ready.
- **Concurrent `/wt merge`s rely on git's atomic ref update.** `merge --ff-only` and the CAS `update-ref` both *refuse* a stale fast-forward rather than clobber, so a race can never lose commits; the bare-ref path uses `update-ref` with an expected old value, never `git branch -f` (a force-move that could). The loser detects it got beaten (step 2's `is-ancestor` check) and re-runs the whole process — rebase onto the now-current default, then fast-forward — until it lands. `/wt delete` doesn't race — it touches only its own worktree.
- Always read the branch from git and handle detached HEAD; run removals from `$SAFE`, never from inside the target.
- The worktree-list parsing avoids awk `$0` and positional `$1`/`$2`: when the skill is invoked with an argument (`/wt merge <name>`), the launcher substitutes those placeholders with the argument tokens, which would corrupt any snippet using them. Named `$VARS` are untouched.
