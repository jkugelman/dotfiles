---
name: dotfiles
description: Working on John's config files — any edit to a dotfile under $HOME (~/.zshrc, ~/.bashrc, ~/.config/git/config, ~/.vimrc, ~/.tmux.conf, ~/.claude/, ~/.local/bin/, ~/.ssh/config, ...) or any Git operation on them. $HOME is the work tree of a bare repo at ~/.dotfiles, so plain `git` does not work there, edits change live config, and new files need `add -f`. Covers the `dotfiles` command, the ignore allowlist, why worktree isolation doesn't apply here, and local.* machine overrides.
---

# Working on the dotfiles repo

My config files live in a bare Git repo: `~/.dotfiles` is the Git directory and
`$HOME` itself is the work tree. The repo is **public** at
`github.com/jkugelman/dotfiles` and its default branch is `main`. Everything
below follows from that one unusual fact. The README lives at
`~/.github/README.md` — out of sight in `$HOME`, still rendered by GitHub.

## Use `dotfiles`, not `git`

There's no `.git` in `$HOME`, and `~/.dotfiles` is not a checkout, so both
obvious reflexes fail:

- `cd ~/.dotfiles && git status` → `fatal: this operation must be run in a work tree`
- plain `git status` in `$HOME` → finds nothing, or some unrelated repo

Use the `dotfiles` function:

```sh
dotfiles status
dotfiles diff
dotfiles add ~/.vimrc
```

It's defined in `~/.config/common.shrc` as:

```sh
git --git-dir="$HOME"/.dotfiles --work-tree="$HOME" "$@"
```

Interactive shells and Claude Code's tool calls have it. Non-interactive shells
(`sh -c`, `zsh -c`, scripts) do **not** — they never source the rc files. Spell
out the full `--git-dir` form there, and write `"$HOME"`, not `~`: a tilde in
`--git-dir=~/...` is not expanded (it isn't at the start of the word), and Git
fails with `fatal: not a git repository: '~/.dotfiles'`.

## Tracking a new file needs `add -f`

`~/.gitignore` ignores everything in `$HOME` by default, opting in only to the
directories whose new files should be tracked automatically: `.claude/commands/`,
`.claude/scripts/`, `.claude/skills/`, `.config/bacon/`, `.config/colorls/`,
`.github/`, `.tmux/`, and the `.vim/` subdirectories. New files there are picked
up normally.

Anywhere else — a new top-level dotfile, a script in `~/.local/bin`, anything in
`~/.ssh` — Git refuses:

```
The following paths are ignored by one of your .gitignore files:
.newrc
hint: Use -f if you really want to add them.
```

That's deliberate, not a bug to route around: `~/.local/bin` is mixed in with
pip and npm console shims, and `~/.ssh` holds keys. Just force it:

```sh
dotfiles add -f ~/.newrc
```

**Don't add a `!` line for an individual file.** `.gitignore` never affects a
file that's already tracked, so the instant it's added the ignore rule stops
applying to it — a `!` line would be dead weight, duplicating `git ls-files`
somewhere it can only drift out of sync. `!` lines are only for directories
whose new files should *all* be tracked automatically.

## `$HOME` is live config

Tracked files are the running config, not copies of it — editing `~/.zshrc`
changes my shell, and breaking it breaks my terminal at the next prompt.
Syntax-check after editing:

```sh
bash -n ~/.bashrc
zsh -n ~/.zshrc
```

## Don't isolate this work in a worktree

Edit `$HOME` in place. `EnterWorktree` needs a `.git` in the working directory
to recognize a repo, and `$HOME` has none, so it fails with "not in a git
repository and no WorktreeCreate hooks are configured". Agents that isolate by
default — background jobs — should skip the attempt rather than try it and fall
back. Nothing enforces isolation here, so edits to `$HOME` land either way, and
I work one agent at a time on this repo, so the collisions isolation would
prevent don't arise.

Don't hand-roll a worktree with `git worktree add` either, and don't try to make
`EnterWorktree` work by configuring `WorktreeCreate` hooks. Claude Code checks
for that hook *before* it checks for a git repo, so a hook in
`~/.claude/settings.json` would hijack worktree creation in **every** repo, not
just this one — and hook-based worktrees skip the built-in path's
`.worktreeinclude` copying, `symlinkDirectories`, and resume/reset handling.
That was investigated and deliberately rejected.

## Machine-specific settings go in `local.*`

Anything that shouldn't apply to every machine belongs in an untracked local
override rather than in a tracked file. Each config sources one if it exists:

| Tracked config | Local override |
| --- | --- |
| `.bashrc` | `~/.config/local.bashrc` |
| `.zshrc` | `~/.config/local.zshrc` |
| `.config/common.shrc` | `~/.config/local.shrc` |
| `.config/git/config` | `~/.config/git/config.local` |
| `.tmux.conf` | `~/.config/local.tmux.conf` |
| `.screenrc` | `~/.config/local.screenrc` |
| `.ssh/config` | `~/.ssh/config.local` |

`~/.gitignore` keeps these out of the repo, which is their whole point.

## Design preferences

Leanings, not laws — weigh them against the specific case and push back when they
don't fit. Written down to save repeating them, not to settle anything; expect
the list to grow.

**Keep `$HOME` uncluttered.** All else equal, prefer a home directory with few
top-level entries, even hidden ones. Config goes in `~/.config`; the XDG base
dirs have a home for most other things too — `~/.local/state` for per-machine
state that should persist (undo history, logs), `~/.cache` for the throwaway,
`~/.local/share` for the portable. Reach for a new `~/.something` only when a
tool gives no other option.

**Write config in a general, self-contained style.** Prefer a config file that
states a rule anyone could lift out and reuse over one wired to this repo's
specifics. Two habits fall out of that. Favor "use whatever exists" fallbacks
(a list tried by existence) over a hardcoded path or a made-up default. And let
the config *consume* guarantees rather than *create* them: if the repo can
ensure a directory exists (by tracking it) or set an env var, the config
shouldn't also mkdir it or hardcode where it lives — those decisions stay
decoupled, so the same rule works for someone whose setup makes different
promises. The `undodir` line in `.vimrc` is the worked example.

**Prefer managed installs over vendoring.** Reach for a plugin or package manager
(vim-plug, tpm, pipx, brew, a zsh-plugin manager) for third-party code; where
none fits, a documented setup step is the fallback — don't vendor upstream
projects into the repo. Vendoring used to earn its keep by dodging brittle,
bitrot-prone setup and making a fresh machine work on clone; AI-guided setup has
largely erased that cost, so the trade now favors a lean repo over clone-and-go.
Still a lean, not a law: a tiny single-file thing with no clean upstream can stay
vendored when a manager would be more ceremony than it's worth. `~/.zshrc` and
`~/.vimrc` both bootstrap their plugin managers (antidote, vim-plug) on first run
rather than carrying them in-tree.

**Modularize by judgment, not by rule.** Split a config when it's genuinely
unwieldy, sized to the case — a full sourced `.d/` directory when the complexity
earns it, something lighter (like the existing config-plus-unversioned-`local`
split) when that's enough. Aim for clarity balanced against simplicity; don't
impose structure a file doesn't need.
