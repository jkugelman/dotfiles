# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# Fancy prompt.
export PS1='\[\e[0;37m\][$(__ps1_ssh)\[\e[32m\]\u@\h\[\e[0m\]:\[\e[33m\]\w$(__ps1_branch)\[\e[37m\]]\$ \[\e[0m\]'

__ps1_ssh() {
    [[ -n $SSH_CLIENT ]] && printf '\001\e[31m\002ssh\001\e[0m\002 '
}
export -f __ps1_ssh

__ps1_branch() {(
    set -o pipefail

    git rev-parse --abbrev-ref HEAD 2> /dev/null | {
        read branch && printf '\001\e[0m\002 \001\e[0;34m\002(%s)' "$branch"
    } && return

    svn info 2> /dev/null | awk -F': ' '$1=="Relative URL" {print $2}' | {
        IFS= read -r path || return
        name=

        case $path in
            */branches/*)     name=${path##*/branches/};     name=${name%%/*};;
            */Branches/*)     name=${path##*/Branches/};     name=${name%%/*};;
            */dev_branches/*) name=${path##*/dev_branches/}; name=${name%%/*};;
            */tags/*)         name=${path##*/tags/};         name=${name%%/*};;
            */Tags/*)         name=${path##*/Tags/};         name=${name%%/*};;
        esac

        if [[ -n $name ]]; then
            printf '\001\e[0m\002 \001\e[0;34m\002(%s)' "$name"
        fi
    } && return
)}
export -f __ps1_branch

# Start ssh-agent.
SSH_ENV=~/.ssh/environment

if [[ -f $SSH_ENV ]]; then
    . "$SSH_ENV" > /dev/null
fi

if ! { [[ -f $SSH_ENV ]] && [[ -n $SSH_AGENT_PID ]] && kill -0 "$SSH_AGENT_PID" 2> /dev/null; }; then
    ssh-agent -s > "$SSH_ENV" || return
    chmod +x "$SSH_ENV"
    . "$SSH_ENV" > /dev/null
fi

# SVN's auto-completion stinks.
complete -r svn 2> /dev/null

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

# Show the exit codes of failed commands.
trap __exit_code ERR

__exit_code() {
    local exit_code=$?
    ((exit_code == 0)) && return

    # Technique to get the current cursor position courtesty of [Unix.SE]
    # (https://unix.stackexchange.com/questions/88296/get-vertical-cursor-position/183121#183121).
    local row _
    IFS=';' read -sdR -p $'\E[6n' row _
    row="${row#*[}"
    ((row--)) || : # Top-left corner is (1,1), but `tput cup` calls it (0,0).

    # Show the message right-aligned on the previous line. Instead of `tput cup` we
    # could use `tput hpa`, but that doesn't work when `TERM=screen-256color`.
    local message="(exit code $exit_code)"
    local column=$((${#message} < COLUMNS ? COLUMNS - ${#message} : 0))

    printf '%s\e[31m%s\e[0m%s' "$(tput sc; tput cup "$((row-1))" "$((column))")" "$message" "$(tput rc)"
}

# If available, use clang as the default C/C++ compiler.
command -v clang   &> /dev/null && export CC=$(which clang)
command -v clang++ &> /dev/null && export CXX=$(which clang++)

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Source functions/aliases shared with other shells.
[[ ! -f ~/.config/common.shrc ]] || source ~/.config/common.shrc

# Source local customizations.
[[ ! -f ~/.config/local.bashrc ]] || source ~/.config/local.bashrc
