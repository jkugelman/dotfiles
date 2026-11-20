#!/usr/bin/env bash
#
# worktree-name-guard.sh — PreToolUse hook for EnterWorktree.
#
# Denies creating a worktree without a `name`, which would get a random one.
# A descriptive name keeps `git worktree list` and later cleanup legible.
# Entering an existing worktree by `path` passes.
#
# Any internal failure exits 0 silently (allow).

input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0

printf '%s' "$input" | jq -e '
  (.tool_input.name // "" | test("\\S")) or (.tool_input.path // "" | test("\\S"))
' >/dev/null 2>&1 && exit 0

jq -cn '{hookSpecificOutput: {
  hookEventName: "PreToolUse",
  permissionDecision: "deny",
  permissionDecisionReason: "Pass EnterWorktree a `name` that describes the task (e.g. `fix-login-timeout`); without one it gets a random name, which makes `git worktree list` and later cleanup hard to read."
}}'
