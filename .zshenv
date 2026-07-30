# Sourced by EVERY zsh: interactive or not, login or not. That reach is the whole
# point — it is the only startup file a bare `zsh -c`, a shebang script, an
# `ssh host cmd`, an editor subprocess, or a launchd agent will read. ~/.zprofile
# needs a login shell; ~/.zshrc needs an interactive one; those three cases get
# neither.
#
# Keep it minimal, fast, and above all SILENT. Anything printed here corrupts
# non-interactive protocols that expect a clean stream (scp/rsync-over-ssh being
# the classic casualty). Interactive niceties — prompt, aliases, completions,
# keybindings — belong in ~/.zshrc, not here.

# Keep $PATH free of duplicate entries. Set here, before anything touches PATH,
# so the dedup is in force for every shell rather than only interactive ones.
#
# With `-U` the earliest occurrence of a value wins and later copies are dropped.
# That applies to *array* assignments (`path=(new $path)`), which is what makes
# the promotions in ~/.zprofile and ~/.zshrc move an entry to the front instead
# of leaving a stale duplicate behind. It does NOT apply to scalar `PATH=...`
# assignments, so nothing here can launder a string-prepend done elsewhere:
#
#     typeset -U path; path=(/a /usr/bin /b)
#     export PATH="/b:$PATH"   -> /b:/a:/usr/bin:/b   (duplicate survives)
#     path=(/b $path)          -> /b:/a:/usr/bin      (deduped)
typeset -U path fpath

# Homebrew, so that even a bare `zsh -c` can find brew-installed binaries. Only
# makes brew *reachable*; ~/.zprofile handles making it *win* under macOS's
# path_helper. Self-guarded on HOMEBREW_PREFIX *and* on brew being reachable, to
# skip its ~50ms `brew shellenv` fork when already activated without being fooled
# by a half-activated environment — see the file for why both tests are needed.
if [ -r "$HOME/.config/brew.shrc" ]; then
	. "$HOME/.config/brew.shrc"
fi
