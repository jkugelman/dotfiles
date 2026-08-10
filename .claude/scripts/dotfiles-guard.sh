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
#   Edit/Write/MultiEdit on a file in the dotfiles context   -> inject the rules
#   Bash writing to a file in the dotfiles context           -> inject the rules
#   EnterWorktree in the dotfiles context (a creation)       -> deny (edit in place)
#
# "Dotfiles context" is one structural rule, no hardcoded file list: the target
# (the edited file; the write target recovered from a Bash command; the
# session's project dir for EnterWorktree) is under $HOME and there is no
# nested `.git` between it and $HOME. That excludes project checkouts and
# .claude/worktrees/* (they carry their own .git) while still covering
# brand-new files that `dotfiles add -f` would track.
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

# Inject the dotfiles rules for $1, a file in the dotfiles context.
emit_dotfiles_context() {
  local target track msg
  target=$(realpath -m -- "$1" 2>/dev/null || printf '%s' "$1")
  if git --git-dir="$home/.dotfiles" --work-tree="$home" \
    ls-files --error-unmatch -- "$target" >/dev/null 2>&1; then
    track='It is already tracked — commit it with `dotfiles`, not `git`.'
  else
    track='It is NOT tracked yet — if it should be, add it with `dotfiles add -f <path>` (~/.gitignore ignores $HOME by default).'
  fi

  msg=$(printf '⚙ Dotfiles work: %s lives in $HOME, the work tree of the bare repo ~/.dotfiles. %s %s' \
    "~${target#"$home"}" \
    "$track" \
    'Use the `dotfiles` function for all git ops (plain `git` fails in $HOME). Edit in place — never isolate dotfiles work in a worktree. Commit locally only; do not push or open a PR unless asked. Load the `dotfiles` skill for full detail.')

  jq -cn --arg ctx "$msg" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$ctx}}'
}

case "$tool" in
Edit | Write | MultiEdit)
  [ -n "$fp" ] || exit 0
  in_dotfiles_context "$fp" || exit 0
  emit_dotfiles_context "$fp"
  exit 0
  ;;
Bash)
  # A shell edit carries no file_path, so the target has to be recovered from
  # the command text — and which files an arbitrary command writes is not
  # decidable, so this stays a heuristic. It covers the shapes Claude Code's
  # bash-first steering actually produces (sed -i, heredocs, redirects, tee).
  # A miss costs the advisory, not correctness: nothing here blocks.
  #
  # Read separately rather than in the joined `read` above: a heredoc command
  # spans lines, and `read` would stop at the first one.
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)
  [ -n "$cmd" ] || exit 0
  printf '%s' "$cmd" | grep -qE \
    '>|(^|[^[:alnum:]_.-])(sed|perl|tee|dd|truncate|install|cp|mv|ln|rm|touch|mkdir)([^[:alnum:]_.-]|$)' ||
    exit 0

  # Redirect targets may be bare words (`> notes.txt`) and resolve against the
  # command's cwd. Every other candidate must name its path outright: bare
  # words resolved against a cwd that is itself under $HOME — which
  # $CLAUDE_JOB_DIR/tmp always is — would match on nearly any command.
  candidates=$(
    {
      printf '%s' "$cmd" | grep -oE '>>?[[:space:]]*[^[:space:]<>|;&()]+' |
        sed -E 's/^>>?[[:space:]]*//'
      printf '%s' "$cmd" | tr -d "\"'" | tr $' \t\n|;&()<>' '\n' | grep -E '^[~/]'
    } 2>/dev/null | sort -u
  )

  while IFS= read -r tok; do
    [ -n "$tok" ] || continue
    case "$tok" in
    "~") tok=$home ;;
    "~/"*) tok="$home/${tok#\~/}" ;;
    /*) ;;
    *) tok="$cwd/$tok" ;;
    esac
    in_dotfiles_context "$tok" || continue
    emit_dotfiles_context "$tok"
    exit 0
  done <<<"$candidates"
  exit 0
  ;;
EnterWorktree)
  # Entering an existing worktree by path is fine; only block a *creation*
  # (name / default) launched from the dotfiles context.
  [ -z "$wt_path" ] || exit 0

  # Judge the session's project directory, not `.cwd`. EnterWorktree builds a
  # worktree of the session's repo, but `.cwd` follows every Bash `cd` — and
  # background jobs are told to work out of $CLAUDE_JOB_DIR/tmp, i.e.
  # ~/.claude/jobs/<id>/tmp: a non-repo path under $HOME that reads as dotfiles
  # context and would deny worktrees for whatever repo the job is really on.
  # Fall back to `.cwd` only when the env var is missing (older Claude Code);
  # never guess with `pwd`, which is this hook's cwd and not the session's.
  root=${CLAUDE_PROJECT_DIR:-$cwd}
  in_dotfiles_context "$root" || exit 0

  reason=$(printf '%s' 'Do not isolate dotfiles work in a worktree — edit $HOME in place. $HOME is the work tree of the bare repo ~/.dotfiles and has no .git, so worktree isolation does not apply (and adding WorktreeCreate hooks to force it would hijack every repo). Nothing enforces isolation here and John works one agent at a time on this repo. Proceed with the edit directly; use the `dotfiles` function for git ops.')

  jq -cn --arg r "$reason" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
  ;;
*)
  exit 0
  ;;
esac
