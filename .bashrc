# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

PATH="$HOME/bin:$HOME/.local/bin:$PATH"

alias cat='cat -v'
alias cdjavas='cd ~/Software/java-src/'
alias cp='cp -i'
alias diff='diff -u'
alias ftp='yafc'
alias lack='ack --pager="less -R"'
alias ls='ls --color=auto -F --hide="*.o" --hide="*.lo" --hide="*.pyc"'
alias mv='mv -i'
alias rm='rm --preserve-root -I'
alias tree='tree -ACF'
alias vim='vim -p'

export ACK_OPTIONS='--nosmart-case'
export CVSROOT=:pserver:jkugelman@cvs.progeny.net:/usr/local/cvsroot
export EDITOR=vim
export LESS=' -R -P?f%f - .?ltLine?lbs. %lt?lb-%lb.?L of %L.?PB - %PB\%.:?pb%pb\%:?btByte %bt?pB - %pB\%.:-...?e (END).'
export NOSQL_INSTALL=/usr/local/nosql
export PYTHONSTARTUP=~/.pythonrc.py
export SCONSFLAGS='-Q'
export SVN_BASH_COMPL_EXT=username,urls,svnstatus
export VISUAL=vim

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

case $HOSTNAME in
    kaufman)   export JAVA_HOME=/usr/java/jdk1.6.0_06;;
    leviathan) export JAVA_HOME=/usr/lib/jvm/default-java; export MAKEFLAGS=-j8;;
    *rhel64)   export JAVA_HOME=/usr/java/jdk1.7.0_21;;
    *rhel72)   export JAVA_HOME=/usr
esac

if [[ -d ~/IA ]]; then
    export IA_COMMON=~/IA/Common
    . "$IA_COMMON/Support/Environment/ENV"
    . "$IA_COMMON/Support/Environment/bashrc"
    unset -f go
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

# Add a `dotfiles` alias for working with the `.dotfiles` repo.
dotfiles() {
    git --git-dir="$HOME"/.dotfiles --work-tree="$HOME" "$@";
}

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
