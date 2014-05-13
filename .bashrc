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
export PATH=$HOME/bin:$PATH
export PYTHONSTARTUP=~/.pythonrc.py
export SCONSFLAGS='-Q'
export SVN_BASH_COMPL_EXT=username,urls,svnstatus
export VISUAL=vim

if [[ -n $SSH_CLIENT ]]; then
    export PS1='\[\e[0;37m\][\[\e[0;31m\]ssh\[\e[0m\] \[\e[0;32m\]\u@\h\[\e[0m\]:\[\e[33m\]\w\[\e[37m\]]\$ \[\e[0m\]'
else
    export PS1='\[\e[0;37m\][\[\e[0;32m\]\u@\h\[\e[0m\]:\[\e[33m\]\w\[\e[37m\]]\$ \[\e[0m\]'
fi

# SVN's auto-completion stinks.
complete -r svn 2> /dev/null

case $HOSTNAME in
    kaufman)   export JAVA_HOME=/usr/java/jdk1.6.0_06;;
    leviathan) export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64;;
    *rhel64)   export JAVA_HOME=/usr/java/jdk1.7.0_21;;
esac

if [[ -d ~/IA ]]; then
    export TI06APB06=~/IA/TI06
    export APB07=~/IA/APB07
    export TI08APB09=~/IA/TI08_APB09
    export TI10APB09=~/IA/TI10_APB09
    export TI10APB11=~/IA/TI10_APB11
    export TI12APB11=~/IA/TI12_APB11
    export TI12APB13=~/IA/TI12_APB13
    export TI14APB13=~/IA/TI14_APB13
    export IA=$TI14APB13
    . "$IA/Support/Environment/bashrc"
fi

#shopt -s failglob      # Disabled, interferes with Ubuntu's auto `complete'
shopt -u failglob
shopt -u force_fignore
shopt -s extglob

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac
