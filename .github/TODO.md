Dotfiles TODO
=============

A running list. **Delete items as they're addressed — don't check them off.**
Nothing here is numbered and nothing has a checkbox, deliberately: numbers go
stale the moment something in the middle is deleted, and a checked box is just
an item you have to read past forever. An empty section heading means that area
is done; delete the heading too.

Line numbers drift, so each item quotes the offending code. Grep for the snippet
rather than trusting the number.


Discuss before implementing
===========================

**These items are conversation starters, not a work queue to burn down.** Bring
one back with what you found — whether it's still live, what the fix would
actually cost, what it trades against — and get agreement before editing a file.
Appearing on this list is not approval to implement: several items are written
down precisely *because* the right answer isn't settled, and the ones that read
as mechanical are often the ones hiding a design choice. An item that turns out
to be wrong, stale, or not worth it is a good outcome — say so and delete it.

Investigating is always fine, and is the point: grep for the snippet, confirm
the item still describes reality, read enough to say what the fix costs. Do that
first, then talk. The rule is about edits, not about looking.


Guiding preferences
===================

Leanings, not laws — I'm working these out as I go, so weigh them against the
specific case and push back when they don't fit. They're written down to save
repeating them, not to settle anything. Expect this list to grow.

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


Suggested order: macOS first. It's better-defined than the restructuring work,
and it's a useful forcing function — making these files portable is what reveals
which parts are genuinely independent, which is exactly what the zsh/vim
restructure needs to know. Guessing at the seams first means discovering the real
constraints afterward.


macOS: loud breaks
==================

These fail immediately and obviously on a Mac. Cheap to fix, high value.

**`git-large-objects` silently emits nothing.** The `numfmt` call is already
half-macOS-aware:

    "$(command -v gnumfmt || echo numfmt)" --field=2 --to=iec-i ...

but the fallback is `numfmt`, absent on a Mac without `brew install coreutils`.
It's the last stage of a pipeline, so `command not found` discards all the work
upstream and you get zero output. Fall back to an `awk` formatter, or fail with a
message that names the missing dependency.

**`git-revise` has a hardcoded interpreter.** `#!/usr/bin/python3` finds Apple's
stock Python, which won't have `gitrevise` installed. This is a pip-generated
console shim that arguably shouldn't be tracked at all — consider untracking it
and using `pipx install git-revise`.


macOS: silent breaks
====================

These are the dangerous ones. Nothing errors; things just quietly stop doing what
you think they do.

**`.bashrc` never runs at all.** Terminal.app and iTerm2 start bash as a *login*
shell, which reads `.bash_profile` / `.bash_login` / `.profile` — never
`.bashrc`. There's no `.bash_profile` tracked; it was removed in "Remove outdated
.bash_profile." So all of `.bashrc` — prompt, ssh-agent, exit-code trap, the
`common.shrc` source — silently does nothing, and you get a bare `bash-3.2$` with
no hint why. Track a `.bash_profile`:

    [[ -f ~/.bashrc ]] && . ~/.bashrc

(`.bashrc`'s `[ -f /etc/bashrc ]` guard is fine as-is — macOS does ship one.)

**The ssh-agent block detaches you from the macOS Keychain.** In `.bashrc`:

    SSH_ENV=~/.ssh/environment
    if ! { [[ -f $SSH_ENV ]] && [[ -n $SSH_AGENT_PID ]] && kill -0 "$SSH_AGENT_PID" ...

macOS already runs an agent via launchd with Keychain-stored passphrases and
exports `SSH_AUTH_SOCK`. This logic only ever consults `~/.ssh/environment`, so
it spawns a redundant agent and overwrites `SSH_AUTH_SOCK`, detaching you from
every Keychain-backed key. Nothing errors — you just start getting passphrase
prompts you never used to get, permanently. Guard the whole block:

    if [[ -z $SSH_AUTH_SOCK ]]; then ... fi

`.zshrc`'s `plugins/ssh-agent` from oh-my-zsh is redundant on macOS for the same
reason, though it at least respects an existing agent.

**`.pythonrc.py` Tab completion is a no-op.** `readline.parse_and_bind('tab:
complete')` — on macOS Python's `readline` is libedit-backed, not GNU readline,
and libedit takes completely different bind syntax. It's accepted and ignored;
Tab inserts a literal tab forever. Branch on it:

    if 'libedit' in (getattr(readline, '__doc__', '') or ''):
        readline.parse_and_bind('bind ^I rl_complete')
    else:
        readline.parse_and_bind('tab: complete')

**`renumber-screen-windows` renumbers nothing.** macOS ships GNU screen 4.00.03;
the `-Q` query flag arrived in 4.1.0, so every `screen -Q` call fails. Worse, the
failure is masked from `set -euo pipefail`:

    local currentWindow="$(screen -Q title)"

`local` is itself a command, and its exit status wins — the classic bash trap. So
the script exits 0 having done nothing. Split the declaration from the assignment
so `set -e` can see the failure, and note the `brew install screen` dependency.
It's bound to Ctrl-A Space in `.screenrc`, so it just quietly stops working.


macOS: degraded
===============

Not broken, just worse than it should be.

**Nothing from Homebrew is on `PATH`.** Neither `.bashrc`'s `PATH="$HOME/bin:...`
nor `.zshrc`'s `path=(~/.local/bin ~/bin $path)` adds `/opt/homebrew/bin` (Apple
Silicon) or `/usr/local/bin` (Intel), and no `.zprofile` is tracked to run `eval
"$(/opt/homebrew/bin/brew shellenv)"`. On Apple Silicon `/opt/homebrew/bin` is
*not* in the default PATH, so this cascades: no `rg` (breaks `rgl`/`rgll`), no
`tree`, no `numfmt`, no modern `bash`/`screen`/`tmux`.

**`tree` isn't installed on macOS at all** — Homebrew only. The `-ACF` flags
themselves are fine. Worth a note in the README's setup steps alongside Docker.

**`.inputrc` is two-thirds inert.** `$include /etc/inputrc` — macOS has no
`/etc/inputrc`, so the include is silently skipped and you lose the bindings
Debian's copy provides. And `set colored-stats On` needs readline 6.3+; macOS
bash 3.2 bundles readline 5.2, which ignores unknown variables silently.
`visible-stats` and `match-hidden-files` are old enough to work. All no-ops
rather than errors — harmless, just not doing anything.

**`.gitconfig`'s pager breaks under GUI apps.** `pager = diff-so-fancy | less -R`
is fine from a shell, but GUI-launched apps on macOS (IDEs, GitHub Desktop) don't
inherit your rc `PATH`, so git dies with `diff-so-fancy: command not found` on
every `git log`. Consider an absolute path, or override in a local config.

**`.tmux.conf` date format — verify on the device.** The status-right uses `%-d`
and `%-I`; the `-` no-pad flag is a GNU strftime extension that BSD libc
historically lacks, which would render the literal text instead of the date.
Apple's libc may have picked it up — worth checking rather than assuming.
Cosmetic. Portable alternatives are `%e` and `%l`, both POSIX.

**`tput` may print errors at zsh startup.** `.zshrc`'s `tput -T xterm kLFT5` uses
ncurses extended capabilities that macOS's older ncurses may reject with
`unknown terminfo capability` on stderr. The result is properly guarded, so
nothing breaks — Ctrl-Left/Right word-jumping just stops working under
screen/tmux. Add `2>/dev/null`, or hardcode `$'\e[1;5D'` / `$'\e[1;5C'`.


Latent traps (not macOS-specific)
=================================

**Live p10k ordering bug in `.zshrc`.** The instant-prompt block near the top
carries the rule in its own comment: *"Initialization code that may require
console input (password prompts, [y/n] confirmations, etc.) must go above this
block."* About 200 lines below it:

    if ! zplug check --verbose; then
        printf "Install plugins? [y/N]: "
        if read -q; then

That's exactly the console input the rule forbids. It needs to move up with the
zplug bootstrap block at the very top of the file, which already gets this right.
Good evidence that the ordering constraints are real and worth making explicit —
see the restructure section.


Restructure: zsh spine + rc.d
=============================

The problem isn't that `.zshrc` is long, it's that a small order-*critical* spine
is tangled up with a large order-*free* bulk, so everything reads as if it might
be order-sensitive. Roughly 90% of the file has no ordering constraints at all:
the Alt-S/Alt-D git keybindings, history options, the terminfo key table, the
dircycle bindings.

The real constraints are only these, and they're all in the zplug/p10k lifecycle:

  - Input-requiring bootstrap must precede the p10k instant-prompt block.
  - `source ~/.zplug/init.zsh` before any `zplug` call.
  - All `zplug '...'` registrations before `zplug load`.
  - `TAB_TITLE_PREFIX` after `zplug load` (its comment says so).
  - `bindkey -e` early, because it resets the keymap and would clobber later
    `bindkey` calls.

The split:

  - **`.zshrc` is the spine.** Short, and every line is in it *because* it's
    order-critical — with the reason stated. Reading it top to bottom tells you
    the whole lifecycle.
  - **`.config/zsh/rc.d/*.zsh` holds the order-free chunks**, sourced from one
    slot in the spine.
  - **The invariant: if it needs a number, it doesn't belong in `rc.d` — it
    belongs in the spine.** This is what keeps `10-`/`20-`/`50-` from creeping
    back in. "Order matters here" becomes a structural fact rather than a naming
    convention nobody maintains.

Needs a `.gitignore` opt-in for `!/.config/zsh/`.

Once this works for zsh, `.bashrc` gets the same treatment — it has the same
shape, just a smaller spine (no plugin manager, so mostly the ssh-agent block and
prompt setup).


Restructure: vim via native mechanisms
======================================

Don't build a loader — vim already has one, and several current autocmds are
strictly worse than the native equivalent.

**Move filetype detection to `~/.vim/ftdetect/`.** These are all reinventing it:

    autocmd BufReadPre,BufNew *.gradle set filetype=groovy
    autocmd BufReadPre,BufNew SCons*   set filetype=python
    autocmd BufReadPre,BufNew ex*.log  set filetype=iislog

`.vim/ftdetect/less.vim` already exists, so the mechanism is familiar.

**Move per-filetype config to `~/.vim/after/ftplugin/`.** The m4 syntax block and
the wordlist `<F9>` map are the clear candidates.

**Fix `syntax` vs `filetype` confusion.** These set the wrong option:

    autocmd BufRead,BufNewFile *.bats      set syntax=sh
    autocmd BufRead,BufNewFile Dockerfile* set syntax=dockerfile

`filetype` is what you want; `syntax` is a consequence of it.

**Delete the duplicate mappings.** `.vimrc` maps `<Up>`/`<Down>` to `gk`/`gj` in
normal and visual mode, then maps the same four again ~100 lines later under
"Move up and down by visual lines not buffer lines." The second block is entirely
redundant with the first. Exactly the symptom that motivates this whole section.

**Retire the dead vendored plugins in `~/.vim/plugin/`.** This is what blocks
using `plugin/` for your own config — right now it's third-party territory. Most
of it is dead weight: `vcsbzr.vim` (Bazaar), `vcssvk.vim` (SVK), `vcscvs.vim`,
`matchit.vim` (ships with Vim 8 — `packadd matchit`), and
`EnhancedCommentify.vim.bak`, which is a tracked `.bak` file. Move anything still
wanted to vim-plug, delete the rest, and `plugin/` becomes yours for order-free
config.


Cleanup
=======

**`git-commit-with-hash` is misnamed.** It isn't a commit script at all — it's
`git-find-blob`, and its own usage string says so: `usage: git-find-blob <blob>`.
Rename it.

**`cargo-monitor` eats its first argument when run directly.** `shift` runs
unconditionally before the `(($# > 0))` check. Correct when invoked as `cargo
monitor` (cargo passes `monitor` as `$1`), wrong for `cargo-monitor clippy`.

**`.screenrc` errors on a machine with no local override.**

    source ~/.config/local.screenrc

`.tmux.conf` gets this right with `source -q`. Make `.screenrc` match — screen
has a `source` that tolerates missing files, or guard it.


Worth considering
=================

Lower confidence — think about whether these are actually wanted.

**Conditional git identity.** `.gitconfig` hardcodes `email = john@kugelman.name`.
If the Mac is a work machine, `[includeIf "gitdir:~/work/"]` is the clean answer
and keeps the work address out of the public repo.

**Periodic `git gc` on `.dotfiles`.** The 260 MB of unreachable loose objects
that prompted the July 2026 prune came from staging accidents in the era before
`.gitignore` denied `$HOME` by default. That hardening should prevent a
recurrence, so this may be unnecessary — but a bare repo gets no automatic gc
from routine `git` invocations the way a normal checkout does. Worth a look in
six months to see whether it's creeping again.

**Untrack the pip/npm console shims in `~/.local/bin`.** `git-revise` is a
pip-generated shim; `ack` and `diff-so-fancy` are vendored fatpacked Perl. They're
tracked as though they were your scripts, but they're really vendored
dependencies pinned at whatever version was current when you added them. A
setup-script install (`pipx`, `brew`) may serve better than vendoring — at the
cost of the "clone and go" property.
