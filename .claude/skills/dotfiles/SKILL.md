---
name: dotfiles
description: Working on John's config files — any edit to a dotfile under $HOME (~/.zshrc, ~/.bashrc, ~/.gitconfig, ~/.vimrc, ~/.tmux.conf, ~/.claude/, ~/.local/bin/, ~/.ssh/config, ...) or any Git operation on them. $HOME is the work tree of a bare repo at ~/.dotfiles, so plain `git` does not work there, edits change live config, and new files need `add -f`. Covers the `dotfiles` command, the ignore allowlist, worktree isolation for sweeping or parallel edits, and local.* machine overrides.
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
out the full `--git-dir` form there.

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

## Isolate sweeping or parallel work in a worktree

The bare repo spawns ordinary worktrees, and plain `git` works normally inside
one:

```sh
git --git-dir="$HOME"/.dotfiles worktree add /tmp/dotfiles-wt main
```

Write `"$HOME"`, not `~`: the tilde in `--git-dir=~/...` is not expanded (it
isn't at the start of the word), and Git fails with `fatal: not a git
repository: '~/.dotfiles'`.

Use a worktree for anything sweeping, and whenever several agents work at once —
otherwise they collide in `$HOME` and rewrite my live config while I'm using it.
The tradeoff: a worktree's changes aren't live, so anything that needs a real
shell test still has to land in `$HOME`.

## Machine-specific settings go in `local.*`

Anything that shouldn't apply to every machine belongs in an untracked local
override rather than in a tracked file. Each config sources one if it exists:

| Tracked config | Local override |
| --- | --- |
| `.bashrc` | `~/.config/local.bashrc` |
| `.zshrc` | `~/.config/local.zshrc` |
| `.config/common.shrc` | `~/.config/local.shrc` |
| `.tmux.conf` | `~/.config/local.tmux.conf` |
| `.screenrc` | `~/.config/local.screenrc` |
| `.ssh/config` | `~/.ssh/config.local` |

`~/.gitignore` keeps these out of the repo, which is their whole point.
