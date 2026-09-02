#!/usr/bin/env bash
# scripts/kill-ai.sh
# Bound to ESC in the 'ai' submap — force-kills the AI and returns.

# Reset submap first so navigation works immediately
hyprctl dispatch submap reset

# Force kill by PID — no confirmation dialog
PID=$(hyprctl clients -j 2>/dev/null \
    | python3 -c "
import sys, json
clients = json.load(sys.stdin)
for c in clients:
    if c.get('class') == 'generalai-assistant':
        print(c['pid'])
        break
")

if [ -n "$PID" ]; then
    kill -9 "$PID" 2>/dev/null || true
fi

hyprctl dispatch workspace previous
