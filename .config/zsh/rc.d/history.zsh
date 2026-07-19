# Drop older duplicates from history; live sharing across sessions is
# deliberately off.
setopt hist_ignore_all_dups
#setopt share_history

# Keep a large history in memory and on disk. The on-disk file lives under the
# XDG state dir, where the repo tracks .local/state/zsh/ so the directory exists
# — zsh won't create HISTFILE's parent itself.
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history
