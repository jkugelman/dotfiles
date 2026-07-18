# Alt-Left/Right cycle the directory stack (dircycle plugin, loaded from
# ~/.zshrc).
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
