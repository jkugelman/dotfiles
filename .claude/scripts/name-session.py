#!/usr/bin/env python3
"""UserPromptSubmit hook: names a session after what it's about.

Each pass is a `claude -p` call:

1. On the session's first prompt, a lean call (no CLAUDE.md, tools or MCP
   servers) titles it from the prompt alone, or answers LOOKUP when the
   prompt only points elsewhere (a todo item, a PR, a Jira key). On LOOKUP,
   a full call with CLAUDE.md and read-only lookup tools follows the pointer.
2. On the first later prompt after the agent has replied, a lean call
   re-titles it from the transcript, where the agent has usually said what
   the pointer turned out to be.

After both passes the hook exits without a model call. A title set any
other way, such as /rename, is never replaced. State lives in
$XDG_STATE_HOME/name-session: one JSON file per session recording the
title set and the passes run, plus a log.
"""
import json
import os
import subprocess
import sys
from pathlib import Path

STATE = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "name-session"
LOG = STATE / "log.jsonl"
SESSIONS = STATE / "sessions"
MODEL = os.environ.get("NAME_SESSION_MODEL", "sonnet")

# Read-only lookups the model may use to follow a pointer in the first prompt.
LOOKUP_TOOLS = [
    "Read", "Grep", "Glob",
    "Bash(gh pr view:*)", "Bash(gh issue view:*)",
    "mcp__claude_ai_Atlassian_Rovo__getJiraIssue",
]

STYLE = """Write the title in sentence case. If the session is about one obvious reference, start with it and a colon, then capitalize the next word. Write references exactly as "ABC-1234", "PR #1234", "Issue #1234" or "Todo 5", and use "Todos 5 and 6" for two. Example: "PR #1234: Fix relay timeout"."""

GUESS = """Suggest a short title (3-6 words) for this Claude Code session that says what it's about.

If you can't tell what it's about without looking something up, because the prompt only points to something elsewhere such as a numbered item, a PR, a ticket, a file or a link, reply with just LOOKUP instead.

{style}

Reply with the title or LOOKUP only.

User's prompt:
{prompt}"""

LOOKUP = """Suggest a short title (3-6 words) for this Claude Code session that says what it's about.

The prompt points to something elsewhere, such as a numbered item, a PR, a ticket or a file. Use your tools to read it before answering (your CLAUDE.md may say where it is), and title the session after its content.

{style}

Reply with the title only.

User's prompt:
{prompt}"""

REFINE = """Suggest a short title (3-6 words) for this Claude Code session that says what it's about. Where the user's prompt points to something elsewhere, the assistant's replies usually say what it is; title the session after that content.

{style}

Reply with the title only.

{context}"""


def log(entry):
    with LOG.open("a") as f:
        f.write(json.dumps(entry) + "\n")


def texts(content):
    if isinstance(content, str):
        return [content]
    return [c.get("text", "") for c in content or [] if isinstance(c, dict) and c.get("type") == "text"]


def history(path, limit=4):
    """The session's first user prompt and its first few assistant replies."""
    first_user, replies = None, []
    try:
        lines = open(path)
    except OSError:
        return None, []
    for line in lines:
        try:
            o = json.loads(line)
        except ValueError:
            continue
        msg = o.get("message") or {}
        if o.get("type") == "user" and first_user is None and not o.get("isMeta"):
            t = " ".join(texts(msg.get("content"))).strip()
            if t and not t.startswith("<"):
                first_user = t
        elif o.get("type") == "assistant":
            replies += [t.strip() for t in texts(msg.get("content")) if t.strip()]
        if first_user and len(replies) >= limit:
            break
    return first_user, replies[:limit]


def ask(prompt, cwd, tools):
    args = ["claude", "-p", "--model", MODEL, "--no-session-persistence"]
    if tools:
        # Needs CLAUDE.md to know where pointers lead, so it loads the full setup (~40k tokens).
        args += ["--tools", ",".join(t.split("(")[0] for t in tools), "--allowedTools", *tools]
    else:
        # No settings, CLAUDE.md, MCP servers or tools: about 1k tokens of overhead.
        args += ["--tools", "", "--setting-sources", "", "--strict-mcp-config",
                 "--system-prompt", "You write short titles for Claude Code sessions."]
    try:
        out = subprocess.run(
            args, input=prompt, capture_output=True, text=True, timeout=75, cwd=cwd or None,
            env={**os.environ, "NAME_SESSION_INNER": "1"},
        )
    except subprocess.TimeoutExpired:
        return None, "timeout"
    lines = out.stdout.strip().splitlines()
    title = lines[-1].strip(" \"'.*") if lines else ""
    return (title if 0 < len(title) <= 80 else None), out.stderr[-300:]


def main():
    if os.environ.get("NAME_SESSION_INNER"):
        return
    inp = json.load(sys.stdin)
    sid, cwd = inp.get("session_id", ""), inp.get("cwd")
    SESSIONS.mkdir(parents=True, exist_ok=True)
    state_file = SESSIONS / f"{sid}.json"
    state = json.loads(state_file.read_text()) if state_file.exists() else {}

    if state.get("first") and state.get("refine"):
        return  # Both passes done: nothing left to do for this session.

    current = inp.get("session_title")
    if current and current != state.get("title"):
        return  # Titled some other way, such as /rename.

    first, replies = history(inp.get("transcript_path", ""))
    if not state.get("first") and replies:
        state["first"] = True  # Joined mid-session: only the refine pass is left.
    if not state.get("first"):
        pass_name, tools = "first", []
        prompt = GUESS.format(style=STYLE, prompt=inp.get("prompt", "")[:1000])
    elif replies and not state.get("refine"):
        parts = [f"Session's first prompt:\n{first[:600]}"] if first else []
        parts += [f"Assistant reply:\n{r[:500]}" for r in replies]
        pass_name, tools = "refine", []
        prompt = REFINE.format(style=STYLE, context="\n\n".join(parts))
    else:
        return

    state[pass_name] = True
    state_file.write_text(json.dumps(state))
    title, err = ask(prompt, cwd, tools)
    log({"session_id": sid, "pass": pass_name, "title": title, "err": err})
    if pass_name == "first" and title == "LOOKUP":
        prompt = LOOKUP.format(style=STYLE, prompt=inp.get("prompt", "")[:1000])
        title, err = ask(prompt, cwd, LOOKUP_TOOLS)
        log({"session_id": sid, "pass": "lookup", "title": title, "err": err})
    if not title:
        return
    state["title"] = title
    state_file.write_text(json.dumps(state))
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "sessionTitle": title}}))


if __name__ == "__main__":
    main()
