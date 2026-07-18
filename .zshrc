# Bootstrap antidote (zsh plugin manager) and compile the plugin list, both on
# first run only. Deliberately above the instant-prompt block: it may print git
# output the first time, and unlike the old zplug installer it never needs
# input — so nothing here can conflict with instant prompt.
ANTIDOTE_DIR=${XDG_DATA_HOME:-$HOME/.local/share}/antidote
if [[ ! -e $ANTIDOTE_DIR/antidote.zsh ]]; then
    git clone --depth 1 https://github.com/mattmc3/antidote.git $ANTIDOTE_DIR
fi

# antidote compiles ~/.config/zsh/.zsh_plugins.txt into a static file under the
# XDG cache; regenerate only when the plugin list changes. Sourcing it (loading
# the plugins) happens later, once the keybindings below are in place.
zsh_plugins_txt=~/.config/zsh/.zsh_plugins.txt
zsh_plugins_zsh=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zsh_plugins.zsh
if [[ ! $zsh_plugins_zsh -nt $zsh_plugins_txt ]]; then
    mkdir -p ${zsh_plugins_zsh:h}
    (
        source $ANTIDOTE_DIR/antidote.zsh
        antidote bundle <$zsh_plugins_txt >$zsh_plugins_zsh
    )
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Use emacs keybindings even if our EDITOR is set to vi. Need to set this early.
bindkey -e

# Customize completion.
setopt auto_list list_packed

autoload -U compinit
zstyle ':completion:*' menu select=2
zmodload zsh/complist

# compinit's security audit is the slow part of zsh startup. Rebuild the
# dump and run the audit only when it's over a day old; otherwise (fresh,
# or missing on first run) trust the cache with -C.
_zcompdump_stale=(~/.zcompdump(Nmh+24))
if (( $#_zcompdump_stale )); then
    compinit
else
    compinit -C
fi
unset _zcompdump_stale
_comp_options+=(globdots)       # Include hidden files.

# Set window title.
# Based on <https://github.com/mdarocha/zsh-windows-title>
case $TERM in
    xterm*)
        precmd() {
            local dir=${PWD/#$HOME/'~'}
            print -n "\e]0;$dir ❯ ${history[1]}\a"
        }
        ;;
esac

# Alt-Left/Right cycle the directory stack (dircycle plugin, loaded below).
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

# If a command is not recognized in the $PATH, this will use Ubuntu's
# command-not-found package to find it or suggest spelling mistakes.
#
# The oh-my-zsh command-not-found plugin isn't used: it doesn't print an error
# when there's no suggestion.
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

# Drop older duplicates from history; live sharing across sessions is
# deliberately off.
setopt hist_ignore_all_dups
#setopt share_history

# Keep a large history in memory and on disk.
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

# Keep $PATH free of duplicate entries.
typeset -U path

# Enable Powerlevel10k only on 256-color terminals; antidote calls this when it
# sources the plugin list (the conditional: in .zsh_plugins.txt).
is-256color() { [[ $TERM == *256* ]] }

# Load the plugins — late on purpose, so zsh-syntax-highlighting wraps the final
# set of widgets and keybindings defined above.
[[ -r $zsh_plugins_zsh ]] && source $zsh_plugins_zsh
unset ANTIDOTE_DIR zsh_plugins_txt zsh_plugins_zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Source functions/aliases shared with other shells.
[[ ! -f ~/.config/common.shrc ]] || source ~/.config/common.shrc

# Source local customizations.
[[ ! -f ~/.config/local.zshrc ]] || source ~/.config/local.zshrc
