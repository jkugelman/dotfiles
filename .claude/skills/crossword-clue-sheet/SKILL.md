---
name: crossword-clue-sheet
description: Use when John pastes crossword cluing rows copied from Google Sheets (slot, entry, and one or more clue columns) and wants them written into a puzzle's clue-list text file under ~/Library/CloudStorage/Dropbox/Crosswords/Puzzles.
---

# Crossword Clue Sheet

## Overview

John keeps clue ideas in a per-puzzle text file inside the puzzle's folder. A block is
a slot, a space, the entry in capitals, then one clue per line indented 8 spaces:

```
14A NSFW
        URL content warning
        URL opening letters
```

He drafts clues in a Google Sheets table instead. This skill turns a copied
selection from that sheet into blocks and appends them to the text file.

## The sheet

Copying cells from Google Sheets yields tab-separated text. Column 1 is the slot,
column 2 is the entry, and **every remaining column is a clue column** holding one
clue per line. Clue columns feed the block left to right, so the leftmost is the one
that ends up on top. On a collaboration the columns are typically `Chosen` then
`John`; on a solo puzzle there may be just one.

Sheets quotes a cell only when it contains a newline, and leaves quotes inside a
single-line cell unescaped. `"One moment"` is a clue that really does start and end
with quotation marks, not a quoted field. The script handles this; a plain CSV parser
does not.

## Steps

1. Write the paste to a `.tsv` file, tabs intact. Use a heredoc, then check the tab
   count is 3 per record for a 4-column sheet. Losing the tabs silently ruins everything.
2. Find the puzzle folder by title under `~/Library/CloudStorage/Dropbox/Crosswords/Puzzles`.
   The text file is named after the puzzle, without the size or collaborator.
3. Run the converter:

   ```
   ~/.claude/skills/crossword-clue-sheet/sheet2clues.py sheet.tsv -o "<folder>/<Puzzle>.txt"
   ```

   It appends after a blank line and never overwrites. Without `-o` it prints to stdout.
   It reports the entry count and any rows it skipped, such as a header row.
4. Verify. If the folder has a `.jpz`, extract its grid and clue list, then confirm the
   entry count matches, every header's letters match the grid answer, and every block's
   first clue matches the published clue.

## Conventions

| | |
|---|---|
| Entry header | Uppercase, keep the sheet's word spacing, delete everything else. `Elm St.` → `ELM ST`, `T-nut` → `TNUT`, `Is It Cake?` → `IS IT CAKE` |
| Two-line entry cell | Sound-change themes put the grid answer on line 1 and the homophone on line 2. Joined with ` / `: `TREE SURGEON / RESURGENT` |
| Clue text | Verbatim. Keep `<i>` tags, `//` alternatives, quotation marks, ellipses |
| Duplicates | Dropped case- and tag-insensitively, so a chosen `<i>Hearty?</i>` absorbs a plain `Hearty?` below it |
| Blank lines | Dropped. Indented ad hoc notes like `[111D setup]` are kept and re-indented to 8 |
| No clues | The header line stands alone |
| Line endings | Matched to the existing file; LF for a new one. `--crlf` / `--lf` override |

## Common mistakes

- **Feeding it to `csv.reader`.** It strips the quotes off clues like `"Chop chop"`.
- **Rewording a clue.** These are John's notes. Copy them character for character.
- **Sorting the blocks.** Keep the sheet's row order.
- **Overwriting the file.** It often already holds theme brainstorming and grid notes.
