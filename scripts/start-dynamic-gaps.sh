#!/bin/bash
# Launcher for dynamic-gaps.py — kills any existing instance then starts fresh.

PIDFILE="/tmp/dynamic-gaps.pid"

# Kill previous instance using saved PID.
if [ -f "$PIDFILE" ]; then
    old_pid=$(cat "$PIDFILE")
    if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
        kill "$old_pid" 2>/dev/null
        for i in 1 2 3 4 5; do
            kill -0 "$old_pid" 2>/dev/null || break
            sleep 0.1
        done
        kill -9 "$old_pid" 2>/dev/null
    fi
fi

# Save PID then replace this shell with python.
echo $$ > "$PIDFILE"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$SCRIPT_DIR/dynamic-gaps.py" >> /tmp/dynamic-gaps.log 2>&1
