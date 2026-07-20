# Bootstrap antidote (zsh plugin manager) and compile the plugin list, both on
# first run only. Deliberately above the instant-prompt block: it may print git
# output the first time, and unlike the old zplug installer it never needs
# input — so nothing here can conflict with instant prompt.
ANTIDOTE_DIR=${XDG_DATA_HOME:-$HOME/.local/share}/antidote
if [[ ! -e $ANTIDOTE_DIR/antidote.zsh ]]; then
    git clone --depth 1 https://github.com/mattmc3/antidote.git $ANTIDOTE_DIR
fi

# antidote compiles ~/.config/zsh/.zsh_plugins.txt into a static file under the
# XDG cache; regenerate only when the plugin list changes. Sourcing it (loading
# the plugins) happens later, once the keybindings below are in place.
zsh_plugins_txt=~/.config/zsh/.zsh_plugins.txt
zsh_plugins_zsh=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zsh_plugins.zsh
if [[ ! $zsh_plugins_zsh -nt $zsh_plugins_txt ]]; then
    mkdir -p ${zsh_plugins_zsh:h}
    (
        source $ANTIDOTE_DIR/antidote.zsh
        antidote bundle <$zsh_plugins_txt >$zsh_plugins_zsh
    )
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -z $CLAUDECODE && -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Use emacs keybindings even if our EDITOR is set to vi. Must run before any
# `bindkey` below — including the rc.d chunks — since `-e` resets the keymap.
bindkey -e

# Customize completion.
setopt auto_list list_packed

autoload -U compinit
zstyle ':completion:*' menu select=2
zmodload zsh/complist

# compinit's security audit is the slow part of zsh startup. Rebuild the
# dump and run the audit only when it's over a day old; otherwise (fresh,
# or missing on first run) trust the cache with -C. Keep the dump under the
# XDG cache — the antidote block above already ensures ~/.cache/zsh exists.
_zcompdump=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump
_zcompdump_stale=($_zcompdump(Nmh+24))
if (( $#_zcompdump_stale )); then
    compinit -d $_zcompdump
else
    compinit -C -d $_zcompdump
fi
unset _zcompdump _zcompdump_stale
_comp_options+=(globdots)       # Include hidden files.

# Source the order-free config chunks. Everything under rc.d is
# position-independent by construction, so the glob order it loads in never
# matters. This single slot sits after `bindkey -e` (so the chunks' keybindings
# survive the keymap reset) and before the plugins load below (so
# zsh-syntax-highlighting still wraps the final set of widgets). Invariant: if a
# chunk ever needs a number to order it, it belongs in this spine, not rc.d.
for _rc (~/.config/zsh/rc.d/*.zsh(N)); do
    source $_rc
done
unset _rc

# Keep $PATH free of duplicate entries.
typeset -U path

# Enable Powerlevel10k only on 256-color terminals; antidote calls this when it
# sources the plugin list (the conditional: in .zsh_plugins.txt).
is-256color() { [[ $TERM == *256* ]] }

# Load the plugins — late on purpose, so zsh-syntax-highlighting wraps the final
# set of widgets and keybindings defined above.
[[ -r $zsh_plugins_zsh ]] && source $zsh_plugins_zsh
unset ANTIDOTE_DIR zsh_plugins_txt zsh_plugins_zsh

# To customize the prompt, edit ~/.config/zsh/p10k.zsh. Running `p10k
# configure` rewrites the default ~/.p10k.zsh instead, so move its output here.
#
# Claude Code's shell integration gets confused by p10k's prompt and hangs, so
# give it a plain prompt instead. Interactive terminals (including VS Code) are
# unaffected and keep p10k.
if [[ -n $CLAUDECODE ]]; then
    PROMPT='%~ $ '
elif [[ -f ~/.config/zsh/p10k.zsh ]]; then
    source ~/.config/zsh/p10k.zsh
fi

# Source functions/aliases shared with other shells.
[[ ! -f ~/.config/common.shrc ]] || source ~/.config/common.shrc

# Source local customizations.
[[ ! -f ~/.config/local.zshrc ]] || source ~/.config/local.zshrc

# worktrunk (wt) shell integration: defines the wt() cd/exec wrapper and its
# completions. Guarded so it's a harmless no-op on machines without wt.
if command -v wt >/dev/null 2>&1; then
    eval "$(command wt config shell init zsh)"
fi
