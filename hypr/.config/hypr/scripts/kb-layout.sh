#!/usr/bin/env bash
# Returns the active keyboard layout name (first word) for the hyprlock status bar
# Uses bash explicitly to avoid /bin/sh (dash) subshell issues with python3 -c

layout=$(hyprctl devices -j 2>/dev/null \
    | python3 -c "
import sys, json
d = json.load(sys.stdin)
kbs = [k for k in d.get('keyboards', []) if 'power' not in k.get('name', '').lower()]
print(kbs[0]['active_keymap'].split(' ')[0] if kbs else 'US')
" 2>/dev/null)

echo "󰌌 ${layout:-US}"
