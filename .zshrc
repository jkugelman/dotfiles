if ! [[ -d ~/.zplug ]]; then
    printf 'Install zplug? [y/N]: '
    read -q || return
    echo
    curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
    echo
fi

source ~/.zplug/init.zsh

# Use emacs keybindings even if our EDITOR is set to vi. Need to set this early.
bindkey -e

# Automatically cd to my favorite directories.
setopt auto_cd
cdpath=(
    ~/
    ~/cstk
    ~/cstk/toolkit
    ~/cstk/toolkit/legacy
    ~/cstk/distros
    ~/cstk/support
    ~/cstk/test
    ~/IT
)

# Customize completion.
setopt auto_list list_packed

autoload -U compinit
zstyle ':completion:*' menu select=2
zmodload zsh/complist
compinit
_comp_options+=(globdots)       # Include hidden files.

# Set window title.
# Based on <https://github.com/mdarocha/zsh-windows-title>
case $TERM in
    xterm*|termite)
        precmd () {
            dir=${PWD/#$HOME/'~'}
            command=$(history | tail -n1 | awk '{for (i=2;i<=NF-1;i++) printf $i " "; print $NF}')
            print -Pn "\e]0;$dir ❯ $command\a"
        }
        ;;
esac

# Shell theme. Same Powerlevel9k just faster.
zplug 'romkatv/powerlevel10k', as:theme, if:'[[ $TERM == *256* ]]'

# This plugin enables directory navigation similar to using back and forward on
# browsers or common file explorers like Finder or Nautilus. It uses a small zle
# trick that lets you cycle through your directory stack left or right using
# Ctrl + Shift + Left / Right. This is useful when moving back and forth between
# directories in development environments, and can be thought of as kind of a
# nondestructive pushd/popd.
zplug 'plugins/dircycle', from:oh-my-zsh

bindkey '^[[1;3D' insert-cycledleft     # Alt-Left
bindkey '^[[1;3C' insert-cycledright    # Alt-Right

setopt auto_pushd pushd_ignore_dups

# Press Alt-Up to go up a directory, Alt-Down to go back down.
_chdir-parent() {
    cd ..
    _chdir-reset-prompt
}

_chdir-descendant() {
    [[ "${dirstack[1]}" == "$PWD"/* ]] && popd >/dev/null
    _chdir-reset-prompt
}

_chdir-reset-prompt() {
    local fn
    for fn (chpwd $chpwd_functions precmd $precmd_functions); do
        (( $+functions[$fn] )) && $fn
    done
    zle reset-prompt
}

zle -N _chdir-parent
zle -N _chdir-descendant

bindkey '^[[1;3A' _chdir-parent         # Alt-Up
bindkey '^[[1;3B' _chdir-descendant     # Alt-Down

# * ccat <file> [files]: colorize the contents of the file (or files, if more
#   than one are provided). If no arguments are passed it will colorize the
#   standard input or stdin.
#
# * cless <file> [files]: colorize the contents of the file (or files, if more
#   than one are provided) and open less. If no arguments are passed it will
#   colorize the standard input or stdin.
zplug 'plugins/colorize', from:oh-my-zsh

# Fish-like fast/unobtrusive autosuggestions for zsh. It suggests commands as
# you type based on history and completions.
zplug 'zsh-users/zsh-autosuggestions'

# This package provides syntax highlighting for the shell zsh. It enables
# highlighting of commands whilst they are typed at a zsh prompt into an
# interactive terminal. This helps in reviewing commands before running them,
# particularly in catching syntax errors.
zplug 'zsh-users/zsh-syntax-highlighting', defer:2

# This plugin sets title and hardstatus of the tab window for screen, the
# terminal multiplexer.
zplug 'plugins/screen', from:oh-my-zsh

# If a command is not recognized in the $PATH, this will use Ubuntu's
# command-not-found package to find it or suggest spelling mistakes.
#
# Don't use this, it doesn't print an error if there's no suggestion:
# zplug 'plugins/command-not-found', from:oh-my-zsh
if [[ -x /usr/lib/command-not-found ]] ; then
    if (( ! ${+functions[command_not_found_handler]} )) ; then
        function command_not_found_handler {
            [[ -x /usr/lib/command-not-found ]] || return 1
            /usr/lib/command-not-found -- ${1+"$1"} && :
        }
    fi
fi

# Press Alt-L to run `ls`.
_zsh-ls() {
    [[ -z $BUFFER ]] || return 0
    BUFFER='ls'
    zle accept-line
}

zle -N _zsh-ls
bindkey '^[l' _zsh-ls

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

# Press Alt-G to run `git log`.
_zsh-git-log() { _zsh-run-command 'git lg'; }
zle -N _zsh-git-log
bindkey '^[g' _zsh-git-log

# Press Alt-R to reload the shell.
_zsh-reload-shell() { _zsh-run-command "$(printf 'exec %q' "$SHELL")"; }
zle -N _zsh-reload-shell
bindkey '^[r' _zsh-reload-shell

# Press Ctrl-Z to resume vi.
_zsh-resume-vi() { _zsh-run-command 'fg %vi'; }
zle -N _zsh-resume-vi
bindkey '^Z' _zsh-resume-vi

# Run a command if the user hasn't typed anything.
_zsh-run-command() {
    [[ -z $BUFFER ]] || return 0
    BUFFER=$1
    zle accept-line
}

# Pretty ls output.
alias ls='ls -F --color=auto'

# Open files in tabs.
alias vim='vim -p'

# Share history among sessions.
setopt hist_ignore_all_dups share_history

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history.
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history

# Fix Ctrl-Left and Ctrl-Right key bindings.
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

# Use vim.
export EDITOR=vim

# Add to PATH. Don't allow duplicates.
typeset -U path
path=(~/.local/bin ~/bin $path)

# Install plugins if there are plugins that have not been installed.
if ! zplug check --verbose; then
    printf "Install plugins? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

# Then, source plugins and add commands to $PATH.
zplug load

# Customize plugins/screen status line. Have to do this after it's loaded.
TAB_TITLE_PREFIX='"`'$_GET_PATH' | sed "s:..*/::"`$PROMPT_CHAR"'
TAB_TITLE_PROMPT=''

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
