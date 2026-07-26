#!/bin/bash
# Get the touchpad device name dynamically from Hyprland
HYPRLAND_DEVICE=$(hyprctl devices -j | grep -i "touchpad" -A 2 | grep "name" | cut -d '"' -f 4 | head -n 1)

if [ -z "$HYPRLAND_DEVICE" ]; then
    notify-send "Touchpad" "No touchpad device found."
    exit 1
fi

STATUS_FILE="/tmp/touchpad_state"

if [ ! -f "$STATUS_FILE" ] || [ "$(cat $STATUS_FILE)" = "true" ]; then
    hyprctl keyword device["$HYPRLAND_DEVICE"]:enabled false
    echo "false" > "$STATUS_FILE"
    notify-send -i input-touchpad-symbolic "Touchpad" "Disabled"
else
    hyprctl keyword device["$HYPRLAND_DEVICE"]:enabled true
    echo "true" > "$STATUS_FILE"
    notify-send -i input-touchpad-symbolic "Touchpad" "Enabled"
fi
