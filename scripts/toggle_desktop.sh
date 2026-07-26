#!/usr/bin/env bash
# toggle_desktop.sh
# Toggles all windows to show the desktop (and back) by moving them to/from
# a hidden special workspace. Special workspaces are invisible to Waybar.

HIDDEN_WS="special:hidden"
STATE_FILE="/tmp/hypr_desktop_toggle_state"

if [[ -f "$STATE_FILE" ]]; then
    # RESTORE: jq -c '.[]' emits one compact JSON object per line so we can parse each
    while IFS= read -r entry; do
        addr=$(echo "$entry" | jq -r '.addr')
        ws=$(echo "$entry"   | jq -r '.workspace')
        hyprctl dispatch movetoworkspacesilent "$ws,address:$addr"
    done < <(jq -c '.[]' "$STATE_FILE")

    # Focus the first window's original workspace
    ORIG_WS=$(jq -r '.[0].workspace' "$STATE_FILE")
    hyprctl dispatch workspace "$ORIG_WS"

    rm -f "$STATE_FILE"
else
    # MINIMIZE: capture active workspace before moving anything
    ACTIVE_WS=$(hyprctl activeworkspace -j | jq '.id')
    CLIENTS=$(hyprctl clients -j)

    # Only target real workspaces (id > 0); special workspaces already have negative IDs
    VISIBLE=$(echo "$CLIENTS" | jq '[.[] | select(.workspace.id > 0)]')

    COUNT=$(echo "$VISIBLE" | jq 'length')
    if [[ "$COUNT" -eq 0 ]]; then
        exit 0
    fi

    # Save state: address + original workspace id
    echo "$VISIBLE" | jq '[.[] | {addr: .address, workspace: .workspace.id}]' > "$STATE_FILE"

    # Move every window to the hidden special workspace
    echo "$VISIBLE" | jq -r '.[].address' | while read -r addr; do
        hyprctl dispatch movetoworkspacesilent "$HIDDEN_WS,address:$addr"
    done

    # Stay on current (now empty) workspace — shows desktop
    hyprctl dispatch workspace "$ACTIVE_WS"
fi
