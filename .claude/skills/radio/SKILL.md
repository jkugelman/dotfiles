---
name: radio
description: Switch the conversation into walkie-talkie mode — the user sends multiple messages in a row and Claude only responds substantively when they say "over". Activated by /radio on, deactivated by /radio off. Stays active across turns in between.
---

# Radio mode

The user wants to send several piecemeal messages in a row without you replying between them. The mode is controlled by slash command args:

- `/radio on` (or `/radio` with no args) — enter radio mode.
- `/radio off` — exit radio mode.

## On activation (`on`)

Reply with exactly:

> Radio on. Send messages freely — say **over** when you're done and want a response. Type `/radio off` to exit. Over. 📻

Then stop and wait. From this point until `/radio off`, follow the protocol below for every user message.

## On deactivation (`off`)

Reply with exactly:

> Radio off. 📻

Resume normal conversational behavior for the rest of the session. Do not answer any backlog of queued messages unless the user follows up explicitly.

## Protocol while in radio mode

For each user message, look at the trailing signal word(s) (case-insensitive, ignoring trailing punctuation like `.`, `!`, `?`, `,`):

- **Ends with `over`** — they're done with this batch. Treat every message they've sent since the last response (or since `/radio on`) as one combined prompt and respond normally, including tool use. Do not echo or summarize their messages back to them; just answer. Strip the trailing "over" from your interpretation — it's a signal, not part of the request. **End your own response with "Over." too** — same convention applies to you. (Acknowledgment turns that are just `…` don't need it; "over" goes on substantive responses where you're handing the mic back.)
- **Ends with `over and out`** — they're done *and* exiting the mode. Respond normally to the accumulated backlog (per the "over" rule below), then end with a sign-off line: `Over and out. 📻`. Exit radio mode after this turn. Equivalent to `/radio off` after the response.
- **Anything else** — they're still talking. Reply with `…📻…` and nothing else. Do not call tools. Do not ask clarifying questions. Do not acknowledge content. Just `…📻…`.

## Notes

- The user knows the convention. Don't re-explain it on subsequent turns.
- "over" only counts as a signal when it's the **last word** of the message. "I looked it over and…" is not a signal; "…and that's the third thing. over" is.
- If you genuinely cannot proceed without input mid-stream (e.g. a tool requires destructive confirmation), still wait for "over" — queue the question and ask it then.
- Radio mode persists across many turns. Don't drift back to normal behavior just because the conversation is getting long — only `/radio off` exits.
