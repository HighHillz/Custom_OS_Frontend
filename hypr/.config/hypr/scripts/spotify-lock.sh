#!/usr/bin/env bash
# spotify-lock.sh — called by hyprlock cmd[] labels
# Hyprlock strips the user DBus session, so we must set it explicitly.
# Outputs a single space when nothing is playing to avoid hyprlock's
# "Sample Text" fallback for empty cmd[] output.

export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"

MODE="${1:-title}"   # call with "title" or "artist"

status=$(playerctl -p spotify status 2>/dev/null)

if [[ "$status" == "Playing" || "$status" == "Paused" ]]; then
    if [[ "$MODE" == "title" ]]; then
        playerctl -p spotify metadata --format '󰓇  {{title}}' 2>/dev/null
    else
        playerctl -p spotify metadata --format '{{artist}}  ·  {{album}}' 2>/dev/null
    fi
else
    echo ' '   # space — prevents hyprlock "Sample Text" fallback
fi
