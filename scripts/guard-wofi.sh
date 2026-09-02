#!/usr/bin/env bash
# guard-wofi.sh — SUPER+R handler.
# Opens wofi launcher, but is a no-op when on workspace 5 (AI).

CURRENT_WS=$(hyprctl activeworkspace -j 2>/dev/null \
    | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])")

if [ "$CURRENT_WS" = "5" ]; then
    exit 0
fi

wofi --show drun
