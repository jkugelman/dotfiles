# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# Homebrew, the same activation zsh gets from ~/.zshenv. Sourced here rather than
# from ~/.bash_profile so it covers interactive non-login shells too, and early
# enough that the PATH probes below (and anything in common.shrc) see brew's
# binaries. ~/.bash_profile sources this file, so login shells are covered as
# well. Matters most where bash is the daily shell — Linux and WSL.
#
# Bash has no ~/.zshenv equivalent, so a non-interactive, non-login bash (`bash
# -c`, a shebang script) still reads nothing and sees only the PATH it inherited.
# Covering that would mean exporting BASH_ENV, which would make every bash script
# on the system pay for a startup file; not worth it, since such scripts inherit
# an already-activated PATH in practice.
if [ -r "$HOME/.config/brew.shrc" ]; then
    . "$HOME/.config/brew.shrc"
fi

#shopt -s failglob      # Disabled, interferes with Ubuntu's auto `complete'
shopt -u failglob
shopt -u force_fignore
shopt -s extglob

# Space dynamically expands any ! history expansions
bind space:magic-space 2> /dev/null || :

# Use vi-style key bindings
#set -o vi
#bind -m vi-command ".":insert-last-argument

# If this is an xterm set the title to user@host:dir
case "$TERM" in
    xterm*|rxvt*)
        PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
        ;;
    *)
        ;;
esac

# If available, use clang as the default C/C++ compiler.
command -v clang   &> /dev/null && export CC=$(which clang)
command -v clang++ &> /dev/null && export CXX=$(which clang++)

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# Source functions/aliases shared with other shells.
[[ ! -f ~/.config/common.shrc ]] || source ~/.config/common.shrc

# Source local customizations.
[[ ! -f ~/.config/local.bashrc ]] || source ~/.config/local.bashrc
