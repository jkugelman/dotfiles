# Single-key shortcuts that stuff a command into the line editor and run it,
# but only on an empty line — so they never clobber something you're typing.
# Every binding below goes through this helper.
_zsh-run-command() {
    [[ -z $BUFFER ]] || return 0
    BUFFER=$1
    zle accept-line
}

# Press Alt-S to run `git status`.
_zsh-git-status() { _zsh-run-command 'git status'; }
zle -N _zsh-git-status
bindkey '^[s' _zsh-git-status

# Press Alt-D to run `git diff`.
_zsh-git-diff() { _zsh-run-command 'git diff'; }
zle -N _zsh-git-diff
bindkey '^[d' _zsh-git-diff

# Press Alt-C to run `git diff --cached`.
_zsh-git-diff-cached() { _zsh-run-command 'git diff --cached'; }
zle -N _zsh-git-diff-cached
bindkey '^[c' _zsh-git-diff-cached

# Press Alt-L to run `git log`.
_zsh-git-log() { _zsh-run-command 'git lg'; }
zle -N _zsh-git-log
bindkey '^[l' _zsh-git-log

# Press Alt-R to reload the shell.
_zsh-reload-shell() { _zsh-run-command "$(printf 'exec %q' "$SHELL")"; }
zle -N _zsh-reload-shell
bindkey '^[r' _zsh-reload-shell

# Press Ctrl-Z to resume vi.
_zsh-resume-vi() { _zsh-run-command 'fg %vi'; }
zle -N _zsh-resume-vi
bindkey '^Z' _zsh-resume-vi
