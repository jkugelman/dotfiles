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

**Prompt me; don't proceed on silence.** I want to explicitly approve each change
before it happens — a real yes to the specific thing, not "I'll do this unless
you object." Opt-out framing puts the burden on me to catch what got slipped in,
and in a long message it's easy to miss an item and have it sail through
unapproved. So: ask, wait for the yes, then act. Batch related changes into a
short, scannable list I can approve at a glance rather than burying them in prose
— keeping messages tight is part of this, not separate from it.


The list is a starting point, not a boundary
=============================================

This list was seeded by one agent's pass over the repo, and I hadn't vetted it
before it landed — so treat every item as a claim to check, not a decision
already made. And the list is not the *scope*. This is a spring cleaning; the
best finds won't be on it. Actively look for cleanup nobody wrote down, and add
concrete ones here so this stays the shared queue instead of something to work
around.

Two kinds of off-list find weigh as much as bugs:

  - **Delete what I no longer need.** A lot here is bespoke "good enough" tooling
    built for a pre-AI workflow. If the job is a one-off an agent would now just
    do on demand — a wrapper around a shell or git query — the tool earns nothing
    and should go. `dush` and `git-large-objects` went on exactly this reasoning.
  - **Re-engineer good-enough hacks.** Other things work fine but were quick
    personal solutions. AI makes it cheap to redo them as robust versions now,
    often a better use of my time than leaving the hack in place. Flag these even
    when nothing is broken.

Don't manufacture work to fill the list. Curate — a few high-value finds beat a
long tail of trivia, and "this is fine, leave it" is a good answer. When a
cleanup means deleting config for a tool I've stopped using, bring it as a
reviewable delete-list I approve first, never a self-authorized sweep.


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

**Prefer managed installs over vendoring.** Reach for a plugin or package manager
(vim-plug, tpm, pipx, brew, a zsh-plugin manager) for third-party code; where
none fits, a documented setup step is the fallback — don't vendor upstream
projects into the repo. Vendoring used to earn its keep by dodging brittle,
bitrot-prone setup and making a fresh machine work on clone; AI-guided setup has
largely erased that cost, so the trade now favors a lean repo over clone-and-go.
Still a lean, not a law: a tiny single-file thing with no clean upstream can stay
vendored when a manager would be more ceremony than it's worth.

**Modularize by judgment, not by rule.** Split a config when it's genuinely
unwieldy, sized to the case — a full sourced `.d/` directory when the complexity
earns it, something lighter (like the existing config-plus-unversioned-`local`
split) when that's enough. Aim for clarity balanced against simplicity; don't
impose structure a file doesn't need.


Rough order: the macOS-portability items are still a good near-term forcing
function — a MacBook is incoming, and making these files portable reveals which
parts are genuinely independent, which is what the zsh/vim restructures need to
know. But the effort is broader than macOS now: deleting what's obsolete and
moving off vendoring are first-class, not afterthoughts.


macOS: silent breaks
====================

Nothing errors; things just quietly stop doing what you think they do.

**`.bashrc` never runs at all.** (Gated by bash's future.) Terminal.app and
iTerm2 start bash as a *login* shell — `.bash_profile` / `.bash_login` /
`.profile`, never `.bashrc`. None is tracked (`.bash_profile` was removed in
"Remove outdated .bash_profile"), so all of `.bashrc` silently does nothing and
you get a bare `bash-3.2$`. If bash stays, track a `.bash_profile`:

    [[ -f ~/.bashrc ]] && . ~/.bashrc

(`.bashrc`'s `[ -f /etc/bashrc ]` guard is fine — macOS ships one.)

**The ssh-agent block detaches you from the macOS Keychain.** (Gated by bash's
future.) `.bashrc` consults only `~/.ssh/environment`, so on macOS — where
launchd already runs an agent with Keychain passphrases and exports
`SSH_AUTH_SOCK` — it spawns a redundant agent and overwrites the socket, and you
start getting passphrase prompts permanently. Guard the block with
`if [[ -z $SSH_AUTH_SOCK ]]; then ... fi`. (`.zshrc`'s oh-my-zsh
`plugins/ssh-agent` is redundant on macOS too, but at least respects an existing
agent.)

**`.pythonrc.py` Tab completion is a no-op.** `readline.parse_and_bind('tab:
complete')` — macOS Python's readline is libedit-backed with different bind
syntax, so Tab inserts a literal tab. Branch on `'libedit' in readline.__doc__`
and use `bind ^I rl_complete`. (See also the redundancy note under Worth
considering.)


macOS: degraded
===============

Not broken, just worse than it should be.

**Nothing from Homebrew is on `PATH`.** Neither `.bashrc` nor `.zshrc` adds
`/opt/homebrew/bin` (Apple Silicon) or `/usr/local/bin` (Intel), and no
`.zprofile` runs `eval "$(/opt/homebrew/bin/brew shellenv)"`. On Apple Silicon
that's not in the default PATH, so it cascades: no `rg` (breaks `rgl`/`rgll`), no
`tree`, no modern `bash`.

**`tree` isn't installed on macOS** — Homebrew only. The `-ACF` flags are fine.
Worth a note in the README setup steps alongside Docker.

**`.inputrc` is two-thirds inert.** (Relevance gated by bash's future.) `$include
/etc/inputrc` — macOS has none, so those bindings vanish; `set colored-stats On`
needs readline 6.3+ and macOS bash 3.2 ships 5.2. No-ops, not errors.

**`.gitconfig`'s pager breaks under GUI apps.** `pager = diff-so-fancy | less -R`
— GUI-launched macOS apps don't inherit your rc `PATH`, so git dies with
`diff-so-fancy: command not found` on every `git log`. Resolved by the
diff-so-fancy → delta/brew migration (see Vendoring migrations), or use an
absolute path.

**`tput` may print errors at zsh startup.** `.zshrc`'s `tput -T xterm kLFT5` uses
extended capabilities older macOS ncurses may reject on stderr. It's guarded, so
nothing breaks — Ctrl-Left/Right word-jumping just stops working. Add
`2>/dev/null`, or hardcode `$'\e[1;5D'` / `$'\e[1;5C'`.


Big rebuild: replace zplug (the keystone)
=========================================

`zplug` is abandoned (last release 2019) and a known startup drag, and it's the
*root* of two other problems: the p10k instant-prompt ordering bug and both
"Install plugins? [y/N]" hacks. Replacing it — antidote / zinit / sheldon, or
plain native `source` — dissolves all three at once, and it's the natural moment
to do the zsh spine/`rc.d` split below. A real project, not a cleanup pass; not
necessarily now, but it subsumes a lot.

**The ordering bug it fixes.** The instant-prompt block near the top of `.zshrc`
says console input must go *above* it; the `zplug check` / `read -q` install
prompt sits ~200 lines below, in violation. A manager that bootstraps at the top
removes the contradiction.

**The spine/rc.d split it enables.** `.zshrc`'s problem isn't length, it's that a
small order-*critical* spine (the plugin-manager/p10k lifecycle; `bindkey -e`
early, since it resets the keymap) is tangled through a large order-*free* bulk
(the Alt-S/Alt-D git keybindings, history options, the terminfo key table,
dircycle). Split it: `.zshrc` keeps only order-critical lines, each with its
reason stated, so reading top-to-bottom tells the whole lifecycle;
`.config/zsh/rc.d/*.zsh` holds the order-free chunks, sourced from one slot.
Invariant: if a chunk needs a number to order it, it belongs in the spine, not
`rc.d` — that keeps `10-`/`20-`/`50-` from creeping back. Needs a `.gitignore`
opt-in for `!/.config/zsh/`. Once it works for zsh, `.bashrc` could get the same
treatment (smaller spine) — but settle bash's future first.


bash's future (talk before touching `.bashrc`)
==============================================

I use bash occasionally, usually for a minute — that's why the customization is
still there. But roughly half of `.bashrc` is a parallel prompt universe
(`__ps1_ssh`, `__ps1_branch`, the `__exit_code` cursor-position exit-code trap,
manual ssh-agent) duplicating what zsh+p10k already give me, for a shell that on
macOS doesn't even run as a login shell. Open question to talk through in detail:
keep maintaining and porting all that, or freeze it and strip bash back to a
script interpreter? The answer decides a cluster of items — the two macOS bash
breaks above, `.inputrc`'s relevance, and the dead SVN branch-parser +
`complete -r svn` still living in `.bashrc`.


Restructure: vim via native mechanisms
======================================

Vim already has a loader; several autocmds reinvent it. (The dead vendored
plugins that used to clutter `~/.vim/plugin` are gone now, so it's much closer to
being yours.)

**Move filetype detection to `~/.vim/ftdetect/`.** `*.gradle → groovy`,
`SCons* → python`, and `ex*.log → iislog` are reinventing it; `ftdetect/less.vim`
already shows the pattern.

**Move per-filetype config to `~/.vim/after/ftplugin/`.** The m4 syntax block and
the wordlist `<F9>` map are the clear candidates.

**Fix `syntax` vs `filetype`.** `*.bats` and `Dockerfile*` set `syntax=`; you
want `filetype=` (syntax follows from it).

**Delete the duplicate mappings.** `.vimrc` maps `<Up>`/`<Down>` to `gk`/`gj`
twice, ~100 lines apart; the second block is entirely redundant with the first.

(The remaining hand-vendored tpope plugins move to vim-plug — see Vendoring
migrations.)


Vendoring migrations
====================

Per the "prefer managed installs over vendoring" lean, these vendored third-party
tools move out of the repo. Each is *installed*, not deleted — except where a
tool I already use replaces it.

**`git-revise`** — pip-generated console shim with a hardcoded `#!/usr/bin/python3`
that finds Apple's stock Python (no `gitrevise` there). Untrack; `pipx install
git-revise`.

**`ack`** — vendored fatpacked Perl pinned at v1.96 (~2011). I search with
ripgrep now (the `rg` helpers in `common.shrc`); `ack` survives only via the
`lack` wrapper. Drop the vendored copy and the wrapper, or `brew install` a
current ack. (Confirm which.)

**`diff-so-fancy`** — vendored fatpacked Perl (v1.2.6), actively used as the git
pager. Replace with `delta` (brew) or `brew install diff-so-fancy`; this also
fixes the macOS "pager breaks under GUI apps" item above.

**vim tpope plugins** — `commentary`, `abolish`, `endwise` are hand-copied into
`~/.vim/plugin` while the repo already uses vim-plug. Move them to `Plug` lines
and delete the vendored copies. `commentary` is likely wanted; confirm `abolish`
and `endwise`.

The remaining vendored vim plugins (`dragvisuals`, live; `undowarnings` and
`visualguide`, kept) have no clean single-repo upstream, so they stay vendored or
get a documented install — not worth forcing.


XDG relocation (opportunistic — easy wins only)
===============================================

A soft preference, not a crusade: switch to XDG paths when it's easy, lean
practical when a tool resists — if it wants a non-XDG location and can't be
cleanly repointed, accept that. Worth a detailed pass when we get to it. The
zero-friction wins:

  - `~/.config/gitignore-global → ~/.config/git/ignore` — git auto-detects it,
    and it lets the `excludesFile` line in `.gitconfig` go too.
  - `~/.gitconfig → ~/.config/git/config` — git auto-detects it; one fewer
    top-level dotfile.
  - Shell state out of `$HOME`: `.zsh_history`, `.zcompdump`, `.zplug` →
    `~/.local/state` / `~/.cache`. (The p10k instant-prompt cache already honors
    `XDG_CACHE_HOME`, so the pattern exists.)
  - `PYTHONSTARTUP` can point into `~/.config` instead of `~/.pythonrc.py`.

Don't force the ones without native XDG support (`.psqlrc`, `.sqliterc`). Related
policy call: generated artifacts that were or are tracked — vim's `doc/tags` (now
deleted) and the ~1000-line, mostly-boilerplate `.p10k.zsh` — should we stop
tracking them (regenerate locally, keep only hand overrides) or accept them?


Cleanup
=======

**Delete `git-commit-with-hash`.** It's misnamed (`git-find-blob`, per its own
usage string), but the real point is that it's a bespoke wrapper around a query
git now does natively: `git log --all --find-object=<blob>`. Same family as the
already-deleted `dush`/`git-large-objects` — delete, don't rename. (Confirm.)

**Delete `cargo-monitor`.** It has a genuine bug (an unconditional `shift` eats
the first arg when run directly, e.g. `cargo-monitor clippy`), but fixing it is
moot: `bacon` — which I already configure — supersedes it, and its `cargo-watch`
dependency is deprecated. Delete rather than fix. (Confirm.)

**Dead/stale `.zshrc` bits.** The `TAB_TITLE_PREFIX` block near the end
references `$_GET_PATH`/`$PROMPT_CHAR`, variables from oh-my-zsh screen/tmux
plugins that aren't loaded — pure leftover. The window-title `precmd` gates on
`termite` (discontinued 2020) and shells out three processes per prompt. The
history section has a stale "Keep 1000 lines" comment above `HISTSIZE=100000` and
a "Share history" heading over a disabled `share_history`. And `compinit` runs
with no cache fast-path — `compinit -C` on a fresh `~/.zcompdump` speeds startup.

**PATH order differs between shells.** `.bashrc` prepends `~/bin` then
`~/.local/bin`; `.zshrc` does the reverse. A name present in both resolves
differently depending on the shell. Unify — candidate for `common.shrc`.

**`nvm.sh` is sourced eagerly.** `common.shrc` sources `nvm.sh` whenever `~/.nvm`
exists, a well-known startup-latency cost both shells pay every launch.
Lazy-load it, or move to fnm/mise.


Worth considering
=================

Lower confidence — think about whether these are actually wanted.

**Conditional git identity.** `.gitconfig` hardcodes `email = john@kugelman.name`.
If the Mac is a work machine, `[includeIf "gitdir:~/work/"]` keeps a work address
out of the public repo.

**Periodic `git gc` on `.dotfiles`.** The 260 MB of unreachable loose objects
behind the July 2026 prune came from staging accidents before `.gitignore` denied
`$HOME` by default. That hardening should prevent a recurrence, but a bare repo
gets no automatic gc from routine `git` invocations. Worth a look in six months.

**`.pythonrc.py` is mostly redundant.** Beyond the macOS libedit no-op above:
CPython's `sys.__interactivehook__` has auto-enabled completion and history since
3.4, so about all this file still adds over stock behavior is its custom history
path. Consider slimming to that delta, or dropping it.

**`.sqliterc` is stale.** `.mode column` (2014) predates the nicer `.mode
box`/`.mode table` (sqlite 3.39+). Modernize it — or drop it, and the
`.gitconfig` sqlite textconv with it, if the sqlite CLI isn't used.

**`.gitconfig` polish.** Already well-tended; optional additions if
re-engineering for robustness: `rerere.enabled`, `column.ui=auto`,
`branch.sort=-committerdate`, `git maintenance start`.
