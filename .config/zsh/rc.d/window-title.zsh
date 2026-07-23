# Set window title.
# Based on <https://github.com/mdarocha/zsh-windows-title>
case $TERM in
    xterm*)
        precmd() {
            local dir=${PWD/#$HOME/'~'}
            print -n "\e]0;$dir ❯ $(fc -ln -1)\a"
        }
        ;;
esac
