# Drop older duplicates from history; live sharing across sessions is
# deliberately off — each shell keeps its own in-memory history so commands
# don't get mixed together. `inc_append_history` still writes every command
# to HISTFILE right away instead of only at shell exit, so a new shell
# starting up sees the true most recent command instead of something stale.
setopt hist_ignore_all_dups
setopt inc_append_history
#setopt share_history

# Keep a large history in memory and on disk. The on-disk file lives under the
# XDG state dir, where the repo tracks .local/state/zsh/ so the directory exists
# — zsh won't create HISTFILE's parent itself.
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history
