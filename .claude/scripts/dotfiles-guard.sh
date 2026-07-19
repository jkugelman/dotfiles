#!/usr/bin/env bash
#
# dotfiles-guard.sh — PreToolUse hook for dotfiles work.
#
# $HOME is the work tree of the bare repo ~/.dotfiles, so config edits there
# want a different workflow than ordinary project work (the `dotfiles` function
# instead of `git`, `add -f` for new files, no worktree isolation). Agents
# routinely miss this because loading the `dotfiles` skill is a judgement call.
# This hook makes it deterministic:
#
#   Edit/Write/MultiEdit on a file in the dotfiles context  -> inject the rules
#   EnterWorktree in the dotfiles context (a creation)       -> deny (edit in place)
#
# "Dotfiles context" is one structural rule, no hardcoded file list: the target
# is under $HOME and there is no nested `.git` between it and $HOME. That
# excludes project checkouts and .claude/worktrees/* (they carry their own
# .git) while still covering brand-new files that `dotfiles add -f` would track.
#
# The hook never blocks an edit: any internal failure exits 0 (allow) silently.

input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0

home=${HOME%/}

# One jq spawn for the common (non-dotfiles) path. Join on the unit separator
# (0x1f) rather than a tab: tab is an IFS-whitespace char, so `read` would
# collapse runs of them and drop empty fields, shifting later values left.
IFS=$'\x1f' read -r tool fp wt_path cwd < <(
  printf '%s' "$input" |
    jq -r '[.tool_name, .tool_input.file_path, .tool_input.path, .cwd]
           | map(. // "") | join("\u001f")' 2>/dev/null
)

# True if $1 (an absolute file or directory) is inside the dotfiles context:
# under $HOME, with no nested `.git` between it and $HOME.
in_dotfiles_context() {
  local target=$1 dir
  [ -n "$target" ] || return 1
  target=$(realpath -m -- "$target" 2>/dev/null || printf '%s' "$target")
  case "$target" in
    "$home" | "$home"/*) ;;
    *) return 1 ;;
  esac
  if [ -d "$target" ]; then dir=$target; else dir=$(dirname -- "$target"); fi
  while [ "$dir" != "$home" ] && [ "$dir" != "/" ]; do
    [ -e "$dir/.git" ] && return 1 # nested repo -> not dotfiles work
    dir=$(dirname -- "$dir")
  done
  return 0
}

case "$tool" in
Edit | Write | MultiEdit)
  [ -n "$fp" ] || exit 0
  in_dotfiles_context "$fp" || exit 0

  fp_abs=$(realpath -m -- "$fp" 2>/dev/null || printf '%s' "$fp")
  if git --git-dir="$home/.dotfiles" --work-tree="$home" \
    ls-files --error-unmatch -- "$fp_abs" >/dev/null 2>&1; then
    track=$(printf 'It is already tracked — commit it with `dotfiles`, not `git`.')
  else
    track=$(printf 'It is NOT tracked yet — if it should be, add it with `dotfiles add -f <path>` (~/.gitignore ignores $HOME by default).')
  fi

  msg=$(printf '%s %s %s' \
    '⚙ Dotfiles work: this file lives in $HOME, the work tree of the bare repo ~/.dotfiles.' \
    "$track" \
    'Use the `dotfiles` function for all git ops (plain `git` fails in $HOME). Edit in place — never isolate dotfiles work in a worktree. Commit locally only; do not push or open a PR unless asked. Load the `dotfiles` skill for full detail.')

  jq -cn --arg ctx "$msg" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$ctx}}'
  exit 0
  ;;
EnterWorktree)
  # Entering an existing worktree by path is fine; only block a *creation*
  # (name / default) launched from the dotfiles context.
  [ -z "$wt_path" ] || exit 0
  [ -n "$cwd" ] || cwd=$(pwd -P 2>/dev/null)
  in_dotfiles_context "$cwd" || exit 0

  reason=$(printf '%s' 'Do not isolate dotfiles work in a worktree — edit $HOME in place. $HOME is the work tree of the bare repo ~/.dotfiles and has no .git, so worktree isolation does not apply (and adding WorktreeCreate hooks to force it would hijack every repo). Nothing enforces isolation here and John works one agent at a time on this repo. Proceed with the edit directly; use the `dotfiles` function for git ops.')

  jq -cn --arg r "$reason" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
  ;;
*)
  exit 0
  ;;
esac
