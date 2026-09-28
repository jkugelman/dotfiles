---
name: nyt-timing-sync
description: Use when John asks which of his NYT crossword results (acceptances, rejections, publications) are missing from the crowdsourced NYT timing sheet at tinyurl.com/nyttiming, or asks to enter or catch up on them.
---

# Syncing NYT results to the timing sheet

The NYT timing sheet (tinyurl.com/nyttiming) is a crowdsourced dashboard of
how long the NYT takes to accept, reject, and publish puzzles. Constructors
report results through an anonymous Google Form; each response is a row in the
sheet's "Direct Import" tab. John's own tracking spreadsheet records every
submission. This skill finds his NYT results that aren't in the timing sheet
and submits them.

Two scripts, both reading the live sheets:

- `python3 compare.py` lists every NYT result in chronological order, each
  marked ENTERED, MISSING, or POSSIBLE (a timing-sheet row within a typo of
  his dates). `--missing` prints only the missing rows, in submit.py's format.
- `python3 submit.py` reads `name|KIND|bucket|start|end` lines on stdin and
  posts each to the form. It stops at the first entry that doesn't return
  the form's confirmation page.

## Workflow

1. Run `compare.py`. Show John the missing rows as a table, oldest first. If
   every row is ENTERED, tell him he's caught up and stop.
2. Ask John about each POSSIBLE row: it may be his entry with a typo, or
   someone else's. Treat the ones he disowns as missing.
3. Confirm each publish date about to be submitted against his constructor page,
   `https://www.xwordinfo.com/Thumbs?author=John+Kugelman`. Weekday puzzles
   have no title there; identify them by the theme entries in the grid. A
   scheduled date that hasn't run yet won't be listed; check that it lands
   on the right weekday.
4. **Wait for John's explicit go before submitting.** The form is anonymous,
   so a wrong entry can only be fixed by emailing the sheet's maintainers.
5. Pipe the approved rows into `submit.py`, then rerun `compare.py` until
   every row shows ENTERED. The CSV export lags a minute or so behind the form.

## How the tracker maps to the form

- **Scope:** NYT daily puzzles only; Midis are excluded. Accept and reject
  results before March 2023 were never entered, because the sheet doesn't want
  data that old.
- **Weekday buckets:** Mon–Wed → Mo/Tu/We, Thursday → Th, Themeless → Fr/Sa,
  Sunday → Su.
- **Precedence:** the tracker's status columns run left to right in order of
  precedence. A rejection followed by an acceptance (a rejection John talked
  into a revision) gets only an accept row.
- **Accept date for a new row:** the Accepted column, the final acceptance.
  Earlier revision requests were "maybes". Older rows John entered use
  whichever acceptance-type date he picked at the time, so `compare.py` accepts
  any of them as a match.
- **Published puzzles need two rows:** one accept and one publish. The publish
  row's start date is the same final acceptance date.
