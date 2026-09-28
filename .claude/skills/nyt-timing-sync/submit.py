#!/usr/bin/env python3
"""Submit results to the NYT timing sheet's Google Form.

Reads lines of `name|KIND|bucket|start|end` on stdin (KIND is ACCEPT, REJECT,
or PUBLISH; dates are m/d/yyyy) and posts each one. Stops at the first entry
that doesn't get the form's confirmation page.
"""
import re, sys, urllib.parse, urllib.request

FORM = 'https://docs.google.com/forms/d/e/1FAIpQLScdZ99cXLP87vuq0IQbhv0WYJrIWaix8zMwgKc58nfywdSmzw'

# The form branches on its first question. Each branch is a page with a
# weekday bucket and two dates: (answer to the first question, page number,
# bucket entry, start-date entry, end-date entry).
BRANCH = {
    'ACCEPT': ("The NYTimes has ACCEPTED my puzzle (or they've requested a revision)!",
               1, 954670674, 1075363170, 1378576978),
    'REJECT': ('The NYTimes has REJECTED my puzzle.',
               2, 1409589738, 1943094716, 1717390608),
    'PUBLISH': ("The NYTimes has PUBLISHED my puzzle (or they've scheduled it for publication)!",
                3, 660471304, 349372058, 2023212945),
}
FIRST_QUESTION = 913204336
CONFIRMATION = 'Thanks for submitting your info'


def session_token():
    with urllib.request.urlopen(FORM + '/viewform') as r:
        return re.search(r'name="fbzx" value="([^"]*)"', r.read().decode()).group(1)


def submit(token, name, kind, bucket, start, end):
    answer, page, q_bucket, q_start, q_end = BRANCH[kind]
    fields = [(f'entry.{FIRST_QUESTION}', answer), (f'entry.{q_bucket}', bucket)]
    for q, when in ((q_start, start), (q_end, end)):
        month, day, year = when.split('/')
        fields += [(f'entry.{q}_year', year), (f'entry.{q}_month', month), (f'entry.{q}_day', day)]
    fields += [('pageHistory', f'0,{page}'), ('fbzx', token), ('fvv', '1')]
    with urllib.request.urlopen(FORM + '/formResponse', urllib.parse.urlencode(fields).encode()) as r:
        return CONFIRMATION in r.read().decode()


def main():
    token = session_token()
    for line in sys.stdin:
        if not line.strip():
            continue
        name, kind, bucket, start, end = (x.strip() for x in line.split('|'))
        ok = submit(token, name, kind, bucket, start, end)
        print('OK  ' if ok else 'FAIL', name, kind, bucket, start, '->', end)
        if not ok:
            sys.exit(1)


if __name__ == '__main__':
    main()
