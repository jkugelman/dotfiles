#!/usr/bin/env python

import sys, string, math
from math import *

#a = '23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjklmnpqrstuvwxyz!@#$%&*_'
a = string.uppercase + string.digits

for line in sys.stdin:
    h, f = line.strip().split(' ', 1)
    c    = min(int(ceil(log(16**len(h), len(a)))), 16)
    h    = ''.join(a[long(h, 16) // len(a)**(i-1) % len(a)] for i in range(c, 0, -1))
    h    = '-'.join(h[i:i+4] for i in range(0, len(h), 4))

    print h, f
