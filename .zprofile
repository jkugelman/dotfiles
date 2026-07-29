# Login shells. Runs after the system /etc/zprofile, and that ordering is the
# reason this file exists: on macOS /etc/zprofile invokes path_helper, which
# rebuilds PATH from /etc/paths with Apple's directories first. Anything
# ~/.zshenv prepended is demoted behind /usr/bin, so Apple's stock tools would
# shadow Homebrew's newer ones. Promoting brew here — after path_helper has had
# its say — restores the precedence.
#
# Note the division of labour: ~/.zshenv makes brew *reachable* everywhere
# (including non-login, non-interactive shells); this file makes it *win* in
# login shells. Neither alone is sufficient.
#
# Done as an array prepend rather than by re-sourcing ~/.config/brew.shrc, for
# three reasons. It costs no `brew shellenv` fork — ~/.zshenv already exported
# HOMEBREW_PREFIX, so the directories are known. `typeset -U path` dedupes array
# assignments, so this moves the existing entries to the front instead of leaving
# the demoted copies behind (a scalar `PATH=...` prepend would not be deduped).
# And re-sourcing brew.shrc would now do nothing at all: it skips activation
# whenever brew is already on PATH, which after path_helper it still is — just in
# the wrong place.
#
# The (N-/) glob qualifier keeps only entries that exist and are directories, so
# a prefix with no sbin contributes nothing and a stale inherited HOMEBREW_PREFIX
# cannot inject bogus paths. Off Darwin there is usually no path_helper to undo,
# and the prepend is then an idempotent no-op against a PATH already led by brew.

if [[ -n $HOMEBREW_PREFIX ]]; then
	path=($HOMEBREW_PREFIX/{bin,sbin}(N-/) $path)
fi
