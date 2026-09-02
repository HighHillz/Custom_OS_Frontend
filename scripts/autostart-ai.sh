#!/usr/bin/env bash
# autostart-ai.sh
# Launched by Hyprland exec-once at login.
# Ensures the GeneralAI assistant is set up and running on workspace 5.

ASSISTANT_DIR="$HOME/GeneralAI/assistant"
VENV="$ASSISTANT_DIR/venv"
APP="$ASSISTANT_DIR/app.py"
WINDOW_CLASS="generalai-assistant"

# 1. Run setup script (creates venv, starts MCP server) — only if venv not ready
if [ ! -f "$VENV/bin/python3" ]; then
    "$HOME/GeneralAI/scripts/start.sh" --no-mcp
fi

# 2. Start MCP server in background (non-blocking)
"$HOME/GeneralAI/scripts/start.sh" 2>/dev/null &

# Wait a moment for setup to settle
sleep 2

# 3. Launch the assistant on workspace 5 (silent — stays hidden until SUPER+A)
WINDOW_EXISTS=$(hyprctl clients -j 2>/dev/null \
    | python3 -c "
import sys, json
clients = json.load(sys.stdin)
match = next((c['address'] for c in clients if c.get('class') == '$WINDOW_CLASS'), '')
print(match)
")

if [ -z "$WINDOW_EXISTS" ]; then
    kitty \
        --class "$WINDOW_CLASS" \
        --title "GeneralAI Assistant" \
        --override font_family="Maple Mono NF" \
        --override font_size=13 \
        --override background_opacity=0.97 \
        --override background="#060e18" \
        "$VENV/bin/python3" "$APP" &

    # Move it silently to workspace 5 once it appears
    sleep 1.5
    hyprctl dispatch movetoworkspacesilent "5,class:$WINDOW_CLASS" 2>/dev/null || true
fi
