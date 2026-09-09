#!/usr/bin/env python3
"""Convert a Google Sheets cluing table into an indented clue list.

Input is the tab-separated text you get from selecting cells in Google Sheets
and copying.  Column 1 is the slot ("14A"), column 2 is the entry, and every
column after that holds clue candidates, one per line, leftmost column first.

Output is one block per row:

    14A NSFW
            URL content warning
            URL opening letters
"""

import argparse
import os
import re
import sys

INDENT = " " * 8
SLOT_RE = re.compile(r"^\d+[ADad]$")
TAG_RE = re.compile(r"</?[a-z]+>", re.I)


def split_records(text):
    """Split a Sheets paste into records of fields.

    Sheets quotes a cell only when the cell contains a newline, and leaves
    quotes inside a single-line cell unescaped.  So a leading double quote is
    only a CSV quote when the scan closes at a field boundary *and* the value
    spans lines; otherwise the quotes belong to the clue.
    """
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    n = len(text)
    records, row, pos = [], [], 0

    def read_quoted(start):
        buf, j = [], start + 1
        while j < n:
            c = text[j]
            if c == '"':
                if text[j + 1 : j + 2] == '"':
                    buf.append('"')
                    j += 2
                    continue
                if text[j + 1 : j + 2] in ("\t", "\n", ""):
                    return "".join(buf), j + 1
                return None, start
            buf.append(c)
            j += 1
        return None, start

    while pos < n:
        field = None
        if text[pos] == '"':
            value, end = read_quoted(pos)
            if value is not None and "\n" in value:
                field, pos = value, end
        if field is None:
            end = pos
            while end < n and text[end] not in ("\t", "\n"):
                end += 1
            field, pos = text[pos:end], end
        row.append(field)
        if pos < n and text[pos] == "\t":
            pos += 1
        elif pos < n:  # newline
            pos += 1
            records.append(row)
            row = []
    if row:
        records.append(row)
    return [r for r in records if any(f.strip() for f in r)]


def entry_header(cell):
    """"tree surgeon\nresurgent" -> "TREE SURGEON / RESURGENT"."""
    parts = []
    for line in cell.split("\n"):
        letters = re.sub(r"[^0-9A-Za-z ]", "", line).upper()
        letters = " ".join(letters.split())
        if letters:
            parts.append(letters)
    return " / ".join(parts)


def dedupe_key(clue):
    return " ".join(TAG_RE.sub("", clue).split()).casefold()


def convert(text):
    blocks, skipped = [], []
    for record in split_records(text):
        slot = record[0].strip()
        if not SLOT_RE.match(slot):
            skipped.append(slot[:40])
            continue
        header = "%s %s" % (slot.upper(), entry_header(record[1] if len(record) > 1 else ""))
        clues, seen = [], set()
        for cell in record[2:]:
            for line in cell.split("\n"):
                clue = line.strip()
                if not clue:
                    continue
                key = dedupe_key(clue)
                if key and key not in seen:
                    seen.add(key)
                    clues.append(clue)
        blocks.append("\n".join([header.rstrip()] + [INDENT + c for c in clues]))
    return blocks, skipped


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("input", help="tab-separated paste from Google Sheets, or - for stdin")
    ap.add_argument("-o", "--output", help="append to this clue file instead of stdout")
    ap.add_argument("--crlf", action="store_true", help="force CRLF line endings")
    ap.add_argument("--lf", action="store_true", help="force LF line endings")
    args = ap.parse_args()

    text = sys.stdin.read() if args.input == "-" else open(args.input, encoding="utf-8").read()
    blocks, skipped = convert(text)
    if skipped:
        print("skipped %d non-slot row(s): %s" % (len(skipped), ", ".join(skipped)),
              file=sys.stderr)
    print("%d entries" % len(blocks), file=sys.stderr)

    body = "\n".join(blocks) + "\n"

    if not args.output:
        sys.stdout.write(body)
        return

    existing = ""
    if os.path.exists(args.output):
        with open(args.output, encoding="utf-8", newline="") as f:
            existing = f.read()

    newline = "\r\n" if args.crlf else "\n"
    if not (args.crlf or args.lf) and existing.count("\r\n") > existing.count("\n") / 2:
        newline = "\r\n"
    body = body.replace("\n", newline)

    prefix = ""
    if existing.strip():
        if not existing.endswith(("\n", "\r")):
            prefix = newline
        prefix += newline  # blank line between old content and the new list

    with open(args.output, "a", encoding="utf-8", newline="") as f:
        f.write(prefix + body)
    print("appended to %s" % args.output, file=sys.stderr)


if __name__ == "__main__":
    main()
