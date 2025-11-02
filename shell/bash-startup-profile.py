#!/usr/bin/env python3
"""
Bash Startup Profiler

This script profiles bash startup performance by analyzing timestamped execution logs.
It helps identify slow operations in your .bashrc that impact shell startup time.

How it works:
-------------
1. When BASH_PROFILE_STARTUP=1 is set in the environment, the .bashrc file enables
   detailed execution tracing using bash's 'set -x' feature with high-precision
   timestamps (nanosecond resolution).

2. Each command executed during bashrc sourcing is logged to /tmp/bashstart.<PID>.log
   with timestamps in the format: + SECONDS.NANOSECONDS <command>

3. This script parses the log file, calculates time differences between consecutive
   commands, and identifies the slowest operations.

Usage:
------
# Automatic profiling (recommended):
    ./bash-startup-profile.py

    This will:
    - Launch a new bash instance with profiling enabled
    - Measure total execution time
    - Analyze and display the slowest operations
    - Clean up the log file automatically

# Analyze existing log file:
    BASH_PROFILE_STARTUP=1 bash -i -c 'exit'
    ./bash-startup-profile.py /tmp/bashstart.<PID>.log

# Show more results:
    ./bash-startup-profile.py -n 50  # Show top 50 slowest operations

How BASH_PROFILE_STARTUP works:
--------------------------------
The .bashrc file contains this code:

    if [ -n "$BASH_PROFILE_STARTUP" ]; then
      PS4='+ $(date "+%s.%N")\011 '
      exec 3>&2 2>/tmp/bashstart.$$.log
      set -x
    fi

When BASH_PROFILE_STARTUP is set (to any non-empty value):
- PS4 sets the trace prompt to include high-precision timestamps
- stderr is redirected to a log file
- 'set -x' enables command tracing
- At the end of bashrc, 'set +x' disables tracing

Note: Profiling adds significant overhead (~5-6 seconds) due to 'set -x' logging.
      Real startup time (without profiling) is typically much faster (<100ms).

Output explanation:
-------------------
The script shows:
1. Total bashrc execution time (includes profiling overhead)
2. Top N slowest individual operations with their execution times

Common slow operations to look for:
- Sourcing large scripts (nvm, rvm, etc.) - consider lazy-loading
- Running external commands (eval "$(command)", brew --prefix, etc.)
- Complex bash completion initialization
"""

import argparse
import heapq
import os
import subprocess
import time as time_module

parser = argparse.ArgumentParser(description='Profile bash startup and analyze results.')
parser.add_argument('filename', nargs='?', help='bashstart log file (if not provided, will profile ~/.bashrc)')
parser.add_argument('-n', default=20, help='number of results to show')
args = parser.parse_args()
n = int(args.n)

# If no filename provided, run profiling automatically
if args.filename is None:
    env = os.environ.copy()
    env['BASH_PROFILE_STARTUP'] = '1'

    bashrc_path = os.path.expanduser('~/.bashrc')

    # Source bashrc and measure total time
    # Don't pipe stdout/stderr so bash sees a TTY and runs normally
    start = time_module.time()
    proc = subprocess.Popen(
        ['bash', '-i', '-c', 'exit'],
        env=env,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )
    proc.wait()
    total_time = time_module.time() - start

    # The log file will be /tmp/bashstart.<PID>.log
    filename = f'/tmp/bashstart.{proc.pid}.log'

    if not os.path.exists(filename):
        print(f"Error: Profile log file not found at {filename}")
        exit(1)

    cleanup = True
    print(f"Total bashrc execution time: {total_time:.6f} seconds")
    print()
else:
    filename = args.filename
    cleanup = False
    total_time = None

try:
    # Parse the profiling log file
    with open(filename, 'r') as f:
        q = []
        prev_time = None
        for line in f.readlines():
            words = line.split()
            # Skip lines that don't match the trace format: + TIMESTAMP COMMAND
            if len(words) < 3 or '+' not in words[0]:
                continue
            text = ' '.join(words[2:])
            # Parse EPOCHREALTIME timestamp (seconds.microseconds)
            # Convert to float for easier math
            timestamp = float(words[1])
            # Calculate time difference from previous command
            diff = timestamp - prev_time if prev_time is not None else 0
            prev_time = timestamp
            heapq.heappush(q, (diff, text))

    print(f"Top {n} slowest operations:")
    print("-" * 80)
    for diff, text in heapq.nlargest(n, q):
        print(f"{diff:.6f} s: {text}")
finally:
    # Clean up the log file if we created it
    if cleanup and os.path.exists(filename):
        os.remove(filename)
