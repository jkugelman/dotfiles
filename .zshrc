if ! [[ -d ~/.zplug ]]; then
    printf 'Install zplug? [y/N]: '
    read -q || return
    echo
    curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
    sleep 1 # Why is this needed? Without it, init.zsh is missing on Raspberry Pi.
    echo
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source ~/.zplug/init.zsh

# Use emacs keybindings even if our EDITOR is set to vi. Need to set this early.
bindkey -e

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

# This plugin starts automatically ssh-agent to set up and load whichever
# credentials you want for ssh connections.
zplug 'plugins/ssh-agent', from:oh-my-zsh

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

# Run a command if the user hasn't typed anything.
_zsh-run-command() {
    [[ -z $BUFFER ]] || return 0
    BUFFER=$1
    zle accept-line
}

# Share history among sessions.
setopt hist_ignore_all_dups
#setopt share_history

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history.
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history

# Fix key bindings. From https://wiki.archlinux.org/title/Zsh#Key_bindings.
typeset -g -A key

key[Home]="${terminfo[khome]}"
key[End]="${terminfo[kend]}"
key[Insert]="${terminfo[kich1]}"
key[Backspace]="${terminfo[kbs]}"
key[Delete]="${terminfo[kdch1]}"
key[Up]="${terminfo[kcuu1]}"
key[Down]="${terminfo[kcud1]}"
key[Left]="${terminfo[kcub1]}"
key[Right]="${terminfo[kcuf1]}"
key[PageUp]="${terminfo[kpp]}"
key[PageDown]="${terminfo[knp]}"
key[Shift-Tab]="${terminfo[kcbt]}"
key[Ctrl-Left]="${terminfo[kLFT5]}"
key[Ctrl-Right]="${terminfo[kRIT5]}"

# TERM=screen-256color is missing these key entries.
[[ -z "${key[Ctrl-Left]}"  ]] && key[Ctrl-Left]="$(tput -T xterm kLFT5)"
[[ -z "${key[Ctrl-Right]}" ]] && key[Ctrl-Right]="$(tput -T xterm kRIT5)"

[[ -n "${key[Home]}"       ]] && bindkey -- "${key[Home]}"       beginning-of-line
[[ -n "${key[End]}"        ]] && bindkey -- "${key[End]}"        end-of-line
[[ -n "${key[Insert]}"     ]] && bindkey -- "${key[Insert]}"     overwrite-mode
[[ -n "${key[Backspace]}"  ]] && bindkey -- "${key[Backspace]}"  backward-delete-char
[[ -n "${key[Delete]}"     ]] && bindkey -- "${key[Delete]}"     delete-char
[[ -n "${key[Up]}"         ]] && bindkey -- "${key[Up]}"         up-line-or-history
[[ -n "${key[Down]}"       ]] && bindkey -- "${key[Down]}"       down-line-or-history
[[ -n "${key[Left]}"       ]] && bindkey -- "${key[Left]}"       backward-char
[[ -n "${key[Right]}"      ]] && bindkey -- "${key[Right]}"      forward-char
[[ -n "${key[PageUp]}"     ]] && bindkey -- "${key[PageUp]}"     beginning-of-buffer-or-history
[[ -n "${key[PageDown]}"   ]] && bindkey -- "${key[PageDown]}"   end-of-buffer-or-history
[[ -n "${key[Shift-Tab]}"  ]] && bindkey -- "${key[Shift-Tab]}"  reverse-menu-complete
[[ -n "${key[Ctrl-Left]}"  ]] && bindkey -- "${key[Ctrl-Left]}"  backward-word
[[ -n "${key[Ctrl-Right]}" ]] && bindkey -- "${key[Ctrl-Right]}" forward-word

# VSCode needs extra bindings for Home and End.
bindkey -- $'\e[H' beginning-of-line
bindkey -- $'\e[F' end-of-line

# Add to PATH. Don't allow duplicates.
typeset -U path
path=(~/.local/bin ~/bin $path)

# Alias to make working with .dotfiles easier.
dotfiles() {
    git --git-dir="$HOME"/.dotfiles --work-tree="$HOME" "$@"
}

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

# Source functions/aliases shared with other shells.
[[ ! -f ~/.config/common.shrc ]] || source ~/.config/common.shrc

# Source local customizations.
[[ ! -f ~/.config/local.zshrc ]] || source ~/.config/local.zshrc
