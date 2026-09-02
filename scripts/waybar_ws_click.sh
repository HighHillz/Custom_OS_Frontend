#!/usr/bin/env bash
# waybar_ws_click.sh
# Handles workspace button clicks from Waybar.
# Ignores clicks on workspace 5 (AI). All others switch normally.
#
# Waybar passes the workspace name/id via {name} placeholder.

WS="$1"

# Block the AI workspace tab (workspace 5 / name "5")
if [ "$WS" = "5" ]; then
    exit 0
fi

# Switch to the clicked workspace
hyprctl dispatch workspace "$WS"
