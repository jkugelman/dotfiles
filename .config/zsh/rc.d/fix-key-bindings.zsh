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

# terminfo omits these under TERM=screen-256color (tmux/screen); fall back to
# the standard xterm control sequences so Ctrl-Left/Right word-jumping keeps
# working there. Hardcoding the two constants also avoids `tput`, whose
# extended-capability lookup older macOS ncurses rejects on stderr. (The
# fallback is a plain assignment, not a `${...:-$'\e…'}` default — zsh does not
# ANSI-C-expand $'…' inside a :- word, so that form would bind literal `$'…'`.)
[[ -n "${key[Ctrl-Left]}"  ]] || key[Ctrl-Left]=$'\e[1;5D'
[[ -n "${key[Ctrl-Right]}" ]] || key[Ctrl-Right]=$'\e[1;5C'

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

# The $terminfo sequences above are only what the terminal sends while it's in
# keypad application mode. Put it into that mode whenever the line editor is
# active, so those bindings match the bytes that actually arrive. Registering
# through add-zle-hook-widget — rather than a raw `zle -N zle-line-init` —
# composes with the hooks Powerlevel10k sets on the same events instead of
# replacing them.
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
    autoload -Uz add-zle-hook-widget
    _zle-application-mode-start()  { echoti smkx }
    _zle-application-mode-finish() { echoti rmkx }
    add-zle-hook-widget line-init   _zle-application-mode-start
    add-zle-hook-widget line-finish _zle-application-mode-finish
fi
