#!/usr/bin/env bash
# Claude Code status line: model · context meter · dir/worktree/branch.
# Reads the standard status line JSON payload on stdin. See:
# https://code.claude.com/docs/en/statusline
set -uo pipefail

input=$(cat)

# Pull a value out of the payload; prints an empty string when the path is
# absent or null (via jq's `// empty`) or when jq itself errors.
j() { printf '%s' "$input" | jq -r "$1" 2>/dev/null; }

# Compact token count: 512, 84k, 1.1M.
fmt_num() {
    awk -v n="$1" 'BEGIN {
        if (n >= 1000000) printf "%.1fM", n / 1000000;
        else if (n >= 1000) printf "%.0fk", n / 1000;
        else printf "%d", n }'
}

# ANSI colors, kept sparse: the emoji label each segment, so color is reserved
# for a few accents — dim gray structure, white branch and send glyphs, a
# green worktree glyph, and a red near-full context meter.
reset=$'\033[0m'
gray=$'\033[90m'
red=$'\033[31m'
green=$'\033[32m'
white=$'\033[97m'  # bright white, for glyph accents

# Nerd Font glyphs (require a Nerd Font — John has one; otherwise blank boxes).
branch_icon=$'\uf126'    # nf-fa-code_branch
worktree_icon=$'\uf1bb'  # nf-fa-tree
send_icon=$'\uf1d8'      # nf-fa-paper_plane

# Section separator: a dim middot between every part of the line.
sep=" ${gray}·${reset} "

# Cells a rendered string occupies: the colors above take none, and the emoji
# labels take two apiece, so it is the character count plus one per emoji.
disp_width() {
    local s=$1 bare c
    for c in "$reset" "$gray" "$red" "$green" "$white"; do s=${s//"$c"/}; done
    bare=$s
    for c in 🤖 🧠 📁; do s=${s//"$c"/}; done
    printf '%s' $(( 2 * ${#bare} - ${#s} ))
}

join_segments() {
    local out="" seg
    for seg in "$@"; do
        [ -n "$seg" ] || continue
        if [ -n "$out" ]; then out="${out}${sep}${seg}"; else out="$seg"; fi
    done
    printf '%s' "$out"
}

# --- 1. Directory, branch, worktree ---
cwd=$(j '.workspace.current_dir // .cwd // empty')
[ -n "$cwd" ] || cwd="$PWD"

branch=""
in_worktree=no
if git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
    if [ -z "$branch" ]; then
        short_sha=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
        [ -n "$short_sha" ] && branch="detached@${short_sha}"
    fi
    # A linked worktree's git dir lives at .git/worktrees/<name>.
    case "$(git -C "$cwd" --no-optional-locks rev-parse --git-dir 2>/dev/null)" in
        */worktrees/*) in_worktree=yes ;;
    esac
fi

# Worktree name and the project it belongs to. Prefer the payload's worktree
# metadata; fall back to git so plain `git worktree` checkouts work too.
wt_name=""
wt_origin=""
if [ "$in_worktree" = yes ]; then
    wt_name=$(j '.worktree.name // .workspace.git_worktree // empty')
    wt_origin=$(j '.worktree.original_cwd // empty')
    if [ -z "$wt_name" ]; then
        top=$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
        wt_name=${top##*/}
    fi
    if [ -z "$wt_origin" ]; then
        common=$(git -C "$cwd" --no-optional-locks rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
        if [ -n "$common" ]; then
            wt_origin=${common%/.git}
            [ "$wt_origin" = "$common" ] && wt_origin=$(dirname "$common")
        fi
    fi
fi

# In a worktree, show the project directory rather than the .claude/worktrees/…
# path — that path is clutter and just restates the branch/worktree names.
base_dir=${wt_origin:-$cwd}
dir_display=${base_dir/#$HOME/\~}
segment_dir="📁 ${dir_display}"

# Worktree marker sits between directory and branch: when the worktree name is
# already implied by the branch (or there's no name), a bare tree icon says
# "you're in a worktree" and the branch that follows says which; only an
# unrelated worktree name is spelled out.
if [ "$in_worktree" = yes ]; then
    if [ -z "$wt_name" ] \
        || { [ -n "$branch" ] && [[ "$branch" == *"$wt_name"* || "$wt_name" == *"$branch"* ]]; }; then
        segment_dir="${segment_dir}${sep}${green}${worktree_icon}${reset}"
    else
        segment_dir="${segment_dir}${sep}${green}${worktree_icon}${reset} ${wt_name}"
    fi
fi
if [ -n "$branch" ]; then
    segment_dir="${segment_dir}${sep}${white}${branch_icon}${reset} ${branch}"
fi

# --- 2. Model display name ---
model=$(j '.model.display_name // empty')
segment_model=""
[ -n "$model" ] && segment_model="🤖 ${model}"

# --- 3. Context meter (counts up as the window fills) ---
# Work in absolute tokens: the label is the token count in the window, and the
# bar fills that count against the window size. Prefer the real token count,
# then derive it from a pre-calculated percentage, then read the transcript.
window=$(j '.context_window.context_window_size // empty')
[ -n "$window" ] || window=200000

tokens=$(j '.context_window.total_input_tokens // empty')
if [ -z "$tokens" ]; then
    pct=$(j '.context_window.used_percentage // empty')
    if [ -z "$pct" ]; then
        rem=$(j '.context_window.remaining_percentage // empty')
        [ -n "$rem" ] && pct=$(awk -v r="$rem" 'BEGIN { printf "%.4g", 100 - r }')
    fi
    [ -n "$pct" ] && tokens=$(awk -v p="$pct" -v w="$window" 'BEGIN { printf "%.0f", p / 100 * w }')
fi
if [ -z "$tokens" ]; then
    transcript=$(j '.transcript_path // empty')
    if [ -n "$transcript" ] && [ -f "$transcript" ]; then
        usage=$(tac "$transcript" 2>/dev/null \
            | jq -rc 'select(.message.usage != null) | .message.usage' 2>/dev/null \
            | head -n1)
        [ -n "$usage" ] && tokens=$(printf '%s' "$usage" | jq \
            '(.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)')
    fi
fi

segment_ctx=""
if [ -n "$tokens" ] && [ "$tokens" != null ]; then
    pct=$(awk -v t="$tokens" -v w="$window" \
        'BEGIN { p = t / w * 100; if (p < 0) p = 0; if (p > 100) p = 100; printf "%.0f", p }')
    # Compact used/max, e.g. 84k/200k or 512k/1.0M.
    used_fmt=$(fmt_num "$tokens")
    max_fmt=$(fmt_num "$window")
    # Red once the window is nearly full; otherwise default fg.
    ctx_color=""
    [ "$pct" -gt 80 ] 2>/dev/null && ctx_color=$red

    # A meter that fills as the context is used, e.g. ███░░░░░░░ 84k. Built
    # char-by-char so the multibyte blocks survive a non-UTF-8 locale.
    bar_width=10
    # Round to the nearest cell, but keep the bar shy of full until usage truly
    # hits 100%, so a solid bar unambiguously means "full".
    filled=$(awk -v p="$pct" -v w="$bar_width" \
        'BEGIN { n = int(p * w / 100 + 0.5); if (n < 0) n = 0; if (n > w) n = w; if (n >= w && p < 100) n = w - 1; print n }')
    filled_str=""; i=0
    while [ "$i" -lt "$filled" ]; do filled_str="${filled_str}█"; i=$((i + 1)); done
    empty_str=""
    while [ "$i" -lt "$bar_width" ]; do empty_str="${empty_str}░"; i=$((i + 1)); done
    segment_ctx="🧠 ${ctx_color}${filled_str}${gray}${empty_str}${reset} ${ctx_color}${used_fmt}${gray}/${max_fmt}${reset}"
fi

# --- Assemble --- model · context · directory group on the left, submit hint
# held against the right edge.
case ${OSTYPE:-} in
    darwin*) submit_chord="cmd+return" ;;
    *)       submit_chord="ctrl+enter" ;;
esac
hint="${white}${send_icon}${reset} ${submit_chord} ${gray}to submit${reset}"

# Claude Code captures this script's output rather than wiring it to the
# terminal, so tput cannot see the width; it exports COLUMNS instead. It also
# indents the row by two cells, and a third is left empty so a full row cannot
# wrap — overrun is truncated from the right, taking the hint with it.
avail=$(( ${COLUMNS:-80} - 3 ))
hint_w=$(disp_width "$hint")
room=$(( avail - hint_w - 1 ))

# When the row is too narrow the model name goes first and the context meter
# second; the directory group stays, being what says which checkout this is.
left=$(join_segments "$segment_model" "$segment_ctx" "$segment_dir")
[ "$(disp_width "$left")" -gt "$room" ] && left=$(join_segments "$segment_ctx" "$segment_dir")
[ "$(disp_width "$left")" -gt "$room" ] && left=$(join_segments "$segment_dir")

gap=$(( avail - $(disp_width "$left") - hint_w ))
if [ "$gap" -ge 1 ]; then
    printf '%s%*s%s\n' "$left" "$gap" '' "$hint"
else
    printf '%s\n' "$left"
fi
