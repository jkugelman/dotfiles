# ~/.bash_profile — read by login shells only. macOS Terminal.app and iTerm2
# start every window as a login shell (as do ssh sessions and console logins),
# and a login bash reads the first of ~/.bash_profile, ~/.bash_login, ~/.profile
# — never ~/.bashrc. Interactive non-login shells (a terminal on Linux, or
# typing `bash`) read ~/.bashrc directly and skip this file. Sourcing ~/.bashrc
# here makes bash behave the same however it starts, on Linux and macOS.
[[ -f ~/.bashrc ]] && . ~/.bashrc
