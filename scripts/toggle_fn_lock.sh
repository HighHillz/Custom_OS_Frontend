#!/bin/bash

STATE_FILE="$HOME/.cache/fn_lock_state"

if [ ! -f "$STATE_FILE" ]; then
    echo "1" > "$STATE_FILE"
fi

CURRENT=$(cat "$STATE_FILE")

if [ "$CURRENT" = "1" ]; then
    echo "0" > "$STATE_FILE"
    notify-send -t 1500 "Fn Lock" "Disabled" 2>/dev/null || true
else
    echo "1" > "$STATE_FILE"
    notify-send -t 1500 "Fn Lock" "Enabled" 2>/dev/null || true
fi
