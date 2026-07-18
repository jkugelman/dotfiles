# Drop older duplicates from history; live sharing across sessions is
# deliberately off.
setopt hist_ignore_all_dups
#setopt share_history

# Keep a large history in memory and on disk.
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history
