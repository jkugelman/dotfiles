#!/usr/bin/env python3
"""Compare John's crossword tracker against the NYT timing sheet.

Prints every NYT result in chronological order, marked ENTERED, POSSIBLE
(a timing-sheet row within a typo of ours; ask John), or MISSING. With
--missing, prints only the missing rows, in submit.py's input format.
"""
import csv, io, sys, urllib.request
from datetime import date, datetime

TRACKER = ('https://docs.google.com/spreadsheets/d/'
           '1WxrrfC20qIh04a9j8i6wfn7TyglWu8bVNeizYGH2B18/export?format=csv')
TIMING = ('https://docs.google.com/spreadsheets/d/'
          '1P2v2eYLkTp1E90RLgaFaX38J5dpVFG1rFNRcoX3QvYI/export?format=csv&gid=298577141')

# The timing sheet doesn't want results older than this; they were never entered.
# Publish rows are exempt: publications from before the cutoff were entered.
CUTOFF = date(2023, 3, 1)

BUCKET = {'Monday': 'Mo/Tu/We', 'Tuesday': 'Mo/Tu/We', 'Wednesday': 'Mo/Tu/We',
          'Thursday': 'Th', 'Friday': 'Fr/Sa', 'Saturday': 'Fr/Sa',
          'Themeless': 'Fr/Sa', 'Sunday': 'Su'}

# Tracker columns that can mark an acceptance, including "maybes" that later
# turned into acceptances. Any of them may be the date John entered in the past.
ACCEPTISH = ['Theme revision requested', 'Theme approved', 'Refill requested',
             'Fill approved', 'Accepted']


def fetch(url):
    with urllib.request.urlopen(url) as r:
        return list(csv.reader(io.StringIO(r.read().decode('utf-8'))))


def d(s):
    s = (s or '').strip()
    return datetime.strptime(s, '%m/%d/%Y').date() if s[:1].isdigit() else None


def fmt(x):
    return f'{x.month}/{x.day}/{x.year}'


def one_typo(a, b):
    """True if date strings a and b differ by one digit edit or a transposition."""
    if len(a) == len(b):
        diff = [i for i in range(len(a)) if a[i] != b[i]]
        return len(diff) == 1 or (len(diff) == 2 and diff[1] == diff[0] + 1
                                  and a[diff[0]] == b[diff[1]] and a[diff[1]] == b[diff[0]])
    if abs(len(a) - len(b)) != 1:
        return False
    short, long_ = sorted((a, b), key=len)
    return any(long_[:i] + long_[i + 1:] == short for i in range(len(long_)))


def distance(ours, theirs):
    """0 = same date, 1 = plausible typo, None = unrelated."""
    if theirs is None:
        return None
    if ours == theirs:
        return 0
    swapped = (ours.month, ours.day, ours.year) == (theirs.day, theirs.month, theirs.year)
    return 1 if swapped or one_typo(fmt(ours), fmt(theirs)) else None


def timing_rows():
    rows = []
    for r in fetch(TIMING)[1:]:
        filed = datetime.strptime(r[0], '%m/%d/%Y %H:%M:%S').date()
        if 'ACCEPTED' in r[1]:
            rows.append(('ACCEPT', r[2], d(r[3]), d(r[4]), filed))
        elif 'REJECTED' in r[1]:
            rows.append(('REJECT', r[5], d(r[6]), d(r[7]), filed))
        elif 'PUBLISHED' in r[1]:
            rows.append(('PUBLISH', r[8], d(r[9]), d(r[10]), filed))
    return rows


def events():
    """Yield (kind, name, bucket, starts, ends, submit_pair) for each NYT result.

    starts/ends are the dates that count as a match for an existing row;
    submit_pair is the (start, end) to use when submitting a new one.
    """
    header, *body = fetch(TRACKER)
    for row in body:
        m = dict(zip(header, row))
        if m['Venue'] != 'NYT':  # also excludes 'NYT Midi'
            continue
        bucket = BUCKET[m['Difficulty']]
        sub, rej, acc, pub = d(m['Submitted']), d(m['Rejected']), d(m['Accepted']), d(m['Published'])
        acceptish = sorted({x for x in map(d, (m[c] for c in ACCEPTISH)) if x})
        if acceptish and rej:
            # Status columns run left to right in order of precedence: a
            # rejection followed by a later acceptance was never entered as a
            # rejection, and the rejection date may have been entered as the
            # acceptance date.
            acceptish = sorted(set(acceptish) | {rej})
        if sub and sub >= CUTOFF:
            if rej and not acc:
                yield 'REJECT', m['Name'], bucket, [sub], [rej], (sub, rej)
            if acc:
                yield 'ACCEPT', m['Name'], bucket, [sub], acceptish, (sub, acc)
        if pub:
            yield 'PUBLISH', m['Name'], bucket, acceptish, [pub], (acc, pub)


def main():
    rows = timing_rows()
    claimed = set()
    results = []
    evs = list(events())
    # Claim exact matches first so a near-miss can't steal another event's row.
    for strict in (True, False):
        for e in evs:
            if any(r[0] is e for r in results):
                continue
            kind, name, bucket, starts, ends, _ = e
            best = None
            for i, (k, b, s, t, filed) in enumerate(rows):
                if i in claimed or k != kind:
                    continue
                ds = min((x for x in (distance(a, s) for a in starts) if x is not None), default=None)
                de = min((x for x in (distance(a, t) for a in ends) if x is not None), default=None)
                if ds is None or de is None:
                    continue
                if kind != 'PUBLISH' and filed < min(ends):
                    continue  # filed before the response arrived
                score = ds + de + (b != bucket)
                if strict and score:
                    continue
                if not strict and (ds + de == 2 and b != bucket):
                    continue
                if best is None or score < best[0]:
                    best = (score, i)
            if best:
                claimed.add(best[1])
                results.append((e, 'ENTERED' if best[0] == 0 else 'POSSIBLE', rows[best[1]]))
            elif not strict:
                results.append((e, 'MISSING', None))

    results.sort(key=lambda r: (r[0][5][0] or date.min, r[0][0]))
    if '--missing' in sys.argv:
        for (kind, name, bucket, _, _, (a, b)), status, _ in results:
            if status == 'MISSING':
                print(f'{name}|{kind}|{bucket}|{fmt(a)}|{fmt(b)}')
        return
    for (kind, name, bucket, _, _, (a, b)), status, row in results:
        if status == 'ENTERED':
            a, b = row[2], row[3]  # show what's in the sheet
        line = f'{status:8} {kind:7} {name[:34]:34} {bucket:8} {fmt(a)} -> {fmt(b)}'
        if status == 'POSSIBLE':
            line += f'   sheet has {row[1]} {fmt(row[2])} -> {fmt(row[3])}, filed {fmt(row[4])}'
        print(line)


if __name__ == '__main__':
    main()
