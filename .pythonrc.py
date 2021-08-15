# Add auto-completion and a stored history file of commands to your Python
# interactive interpreter. Requires Python 2.0+, readline. Autocomplete is
# bound to the Esc key by default (you can change it - see readline docs).
#
# Store the file in ~/.pystartup, and set an environment variable to point
# to it:  "export PYTHONSTARTUP=~/.pystartup" in bash.

import atexit
import os
import readline
import rlcompleter

history_path = os.path.expanduser("~/.pyhistory")

def save_history(history_path=history_path):
    import readline
    readline.write_history_file(history_path)

if os.path.exists(history_path):
    readline.read_history_file(history_path)

readline.parse_and_bind('tab: complete')
atexit.register(save_history)

del os, atexit, readline, rlcompleter, save_history, history_path

# Auto-imports.
try:
    import matplotlib.pyplot as plt
    import numpy as np
    import scipy
    import scipy.signal
except ImportError:
    pass

try:
    import matplotlib
    matplotlib.use('TkAgg')
except (ImportError, ValueError):
    pass
