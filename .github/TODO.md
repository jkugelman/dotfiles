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


macOS: degraded
===============

Not broken, just worse than it should be.

**`.inputrc` is two-thirds inert.** `$include /etc/inputrc` — macOS has none,
so those bindings vanish; `set colored-stats On` needs readline 6.3+ and macOS
bash 3.2 ships 5.2. No-ops, not errors.


Scrub the vim config — vim is now secondary
===========================================

Vim is no longer my primary editor; VS Code and Claude Code are the daily
drivers, and vim is a "pop in real quick" tool now. So the whole `~/.vim` tree
and `.vimrc` are open to aggressive trimming — the bar for keeping a mapping,
plugin, or autocmd is "do I still reach for this in a quick edit," and deleting
likely beats porting. Worth doing *before* the native-mechanism restructure
below, since some of what that would move may just be cut instead. Bring a
reviewable delete-list to approve first.


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

(The remaining hand-vendored tpope plugins move to vim-plug — see Vendoring
migrations.)


Vendoring migrations
====================

Per the "prefer managed installs over vendoring" lean, these vendored third-party
tools move out of the repo. Each is *installed*, not deleted — except where a
tool I already use replaces it.

The remaining vendored vim plugins (`dragvisuals`, live; `undowarnings` and
`visualguide`, kept) have no clean single-repo upstream, so they stay vendored or
get a documented install — not worth forcing.


XDG relocation (opportunistic — easy wins only)
===============================================

A soft preference, not a crusade: switch to XDG paths when it's easy, lean
practical when a tool resists — if it wants a non-XDG location and can't be
cleanly repointed, accept that. Worth a detailed pass when we get to it.

Don't force the ones without native XDG support (`.psqlrc`, `.sqliterc`). Related
policy call: generated artifacts that were or are tracked — vim's `doc/tags` (now
deleted) and the ~1000-line, mostly-boilerplate `.p10k.zsh` — should we stop
tracking them (regenerate locally, keep only hand overrides) or accept them?


Worth considering
=================

Lower confidence — think about whether these are actually wanted.

**Periodic `git gc` on `.dotfiles`.** The 260 MB of unreachable loose objects
behind the July 2026 prune came from staging accidents before `.gitignore` denied
`$HOME` by default. That hardening should prevent a recurrence, but a bare repo
gets no automatic gc from routine `git` invocations. Worth a look in six months.

**`~/.config/git/config` polish.** Already well-tended; one optional addition
remains if re-engineering for robustness: `git maintenance start`.
