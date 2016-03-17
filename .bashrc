# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

alias cat='cat -v'
alias cdjavas='cd ~/Software/java-src/'
alias cp='cp -i'
alias diff='diff -u'
alias ftp='yafc'
alias lack='ack --pager="less -R"'
alias ls='ls --color=auto -F --hide="*.pyc"'
alias mv='mv -i'
alias rm='rm --preserve-root -I'
alias tree='tree -ACF'
alias vim='vim -p'

export ACK_OPTIONS='--nosmart-case'
export CVSROOT=:pserver:jkugelman@cvs.progeny.net:/usr/local/cvsroot
export EDITOR=vim
export LESS=' -R -P?f%f - .?ltLine?lbs. %lt?lb-%lb.?L of %L.?PB - %PB\%.:?pb%pb\%:?btByte %bt?pB - %pB\%.:-...?e (END).'
export LESSOPEN='| /usr/share/source-highlight/src-hilite-lesspipe.sh %s'
export NOSQL_INSTALL=/usr/local/nosql
export OLD_PATH=
export PATH=$HOME/bin:$PATH
export PYTHONSTARTUP=~/.pythonrc.py
export SCONSFLAGS='-Q'
export SVN_BASH_COMPL_EXT=username,urls,svnstatus
export VISUAL=vim

# Fancy prompt.
export PS1='\[\e[0;37m\][$(__ps1_ssh)\[\e[32m\]\u@\h\[\e[0m\]:\[\e[33m\]\w$(__ps1_branch)\[\e[37m\]]\$ \[\e[0m\]'

__ps1_ssh() {
    [[ -n $SSH_CLIENT ]] && printf '\001\e[31m\002ssh\001\e[0m\002 '
}

__ps1_branch() {(
    set -o pipefail

    svn info 2> /dev/null | awk -F': ' '$1=="Relative URL" {print $2}' | {
        IFS=/ read _ _ _ type dir _ || return

        case $type in
            Trunk)    ;;
            Branches) printf '\001\e[0m\002 \001\e[0;34m\002(%s)' "$dir";;
            *)        printf '\001\e[0m\002 \001\e[0;34m\002(%s)' "$type/$dir";;
        esac
    } && return

    git rev-parse --abbrev-ref HEAD 2> /dev/null | {
        read branch || return

        case $branch in
            master)   ;;
            *)        printf '\001\e[0m\002 \001\e[0;34m\002(%s)' "$branch";;
        esac
    } && return
)}

# SVN's auto-completion stinks.
complete -r svn 2> /dev/null

case $HOSTNAME in
    kaufman)   export JAVA_HOME=/usr/java/jdk1.6.0_06;;
    leviathan) export JAVA_HOME=/usr/lib/jvm/java-8-oracle;;
    *rhel64)   export JAVA_HOME=/usr/java/jdk1.7.0_21;;
esac

if [[ -d ~/IA ]]; then
    export IA_COMMON=~/IA/Common
    . "$IA_COMMON/Support/Environment/ENV"
    . "$IA_COMMON/Support/Environment/bashrc"
fi

#shopt -s failglob      # Disabled, interferes with Ubuntu's auto `complete'
shopt -u failglob
shopt -u force_fignore
shopt -s extglob


bind space:magic-space  # Space dynamically expands any ! history expansions

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
trap __exitCode ERR

__exitCode() {
    local exitCode=$?
    
    if ((exitCode != 0)); then
        local msg="(exit code $exitCode)"
        local spaces=$((${#msg} < COLUMNS ? COLUMNS - ${#msg} : 0))

        printf '%s\e[31m%s\e[0m%s' "$(tput sc; tput cuu1; tput hpa "$spaces")" "$msg" "$(tput rc)"
    fi
}

