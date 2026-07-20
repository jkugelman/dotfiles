# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
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

# worktrunk (wt) shell integration: defines the wt() cd/exec wrapper and its
# completions. Guarded so it's a harmless no-op on machines without wt.
if command -v wt >/dev/null 2>&1; then
    eval "$(command wt config shell init bash)"
fi
