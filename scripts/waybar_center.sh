#!/usr/bin/env bash
# waybar_center.sh — interval mode (runs once per poll, outputs one JSON line)
#
# State machine via sentinel files:
#   /tmp/waybar_hud_exit   → "TYPE CLASSES" — emit exit animation for one poll
#   /tmp/waybar_hud_enter  → exists          — emit clock-enter for one poll

VOL_HUD_FLAG="/tmp/waybar_volume_hud"
BRIGHT_HUD_FLAG="/tmp/waybar_brightness_hud"
CHARGING_HUD_FLAG="/tmp/waybar_charging_hud"
HUD_EXIT_FILE="/tmp/waybar_hud_exit"    # content: "volume-hud vol-4" etc.
HUD_ENTER_FILE="/tmp/waybar_hud_enter"  # exists = emit clock-enter this poll
HUD_DURATION=3

# ── HUD content getters ──────────────────────────────────────────────────────

get_volume_class() {
    local raw vol
    raw=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
    [[ "$raw" == *MUTED* ]] && echo "volume-hud muted" && return
    vol=$(echo "$raw" | awk '{printf "%d", $2 * 100}')
    [[ -z "$vol" ]] && vol=0
    if   [[ $vol -ge 81 ]]; then echo "volume-hud vol-5"
    elif [[ $vol -ge 61 ]]; then echo "volume-hud vol-4"
    elif [[ $vol -ge 41 ]]; then echo "volume-hud vol-3"
    elif [[ $vol -ge 21 ]]; then echo "volume-hud vol-2"
    else                          echo "volume-hud vol-1"
    fi
}

get_volume_text() {
    local raw vol icon
    raw=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
    [[ "$raw" == *MUTED* ]] && echo "󰖁  Muted" && return
    vol=$(echo "$raw" | awk '{printf "%d", $2 * 100}')
    [[ -z "$vol" ]] && vol=0
    if   [[ $vol -ge 41 ]]; then icon="󰕾"
    elif [[ $vol -ge 21 ]]; then icon="󰖀"
    else                          icon="󰕿"
    fi
    echo "$icon  $vol%"
}

get_brightness_class() {
    local raw vol
    raw=$(brightnessctl -m 2>/dev/null | awk -F, '{print $4}' | tr -d '%')
    vol=${raw:-0}
    if   [[ $vol -ge 81 ]]; then echo "brightness-hud bright-5"
    elif [[ $vol -ge 61 ]]; then echo "brightness-hud bright-4"
    elif [[ $vol -ge 41 ]]; then echo "brightness-hud bright-3"
    elif [[ $vol -ge 21 ]]; then echo "brightness-hud bright-2"
    else                          echo "brightness-hud bright-1"
    fi
}

get_brightness_text() {
    local raw vol icon
    raw=$(brightnessctl -m 2>/dev/null | awk -F, '{print $4}' | tr -d '%')
    vol=${raw:-0}
    if   [[ $vol -ge 66 ]]; then icon="󰃠"
    elif [[ $vol -ge 33 ]]; then icon="󰃟"
    else                          icon="󰃞"
    fi
    echo "$icon  $vol%"
}

emit_clock()       { printf '{"text":" %s","class":"clock"}\n'       "$(date '+%H:%M    %d %b %Y')"; }
emit_clock_enter() { printf '{"text":" %s","class":"clock-enter"}\n' "$(date '+%H:%M    %d %b %Y')"; }


# Returns 0 and outputs JSON if HUD is live; returns 1 if stale/absent

check_hud() {
    local flag=$1 type=$2
    [[ ! -f "$flag" ]] && return 1
    local t now elapsed
    t=$(cat "$flag" 2>/dev/null)
    now=$(date +%s)
    elapsed=$(( now - ${t:-0} ))
    if [[ $elapsed -lt $HUD_DURATION ]]; then
        # HUD live — save class+text for potential exit animation next poll
        local cls txt
        case "$type" in
            volume)
                cls=$(get_volume_class); txt=$(get_volume_text)
                printf '{"text":"%s","class":"%s"}\n' "$txt" "$cls"
                ;;
            brightness)
                cls=$(get_brightness_class); txt=$(get_brightness_text)
                printf '{"text":"%s","class":"%s"}\n' "$txt" "$cls"
                ;;
            charging)
                local cap=""
                [[ -f /sys/class/power_supply/BAT0/capacity ]] && cap="$(cat /sys/class/power_supply/BAT0/capacity)%"
                cls="charging-hud"; txt="󱐋  Charging  $cap"
                printf '{"text":"%s","class":"%s"}\n' "$txt" "$cls"
                ;;
        esac
        # Store for exit animation (class only; text recomputed live is fine)
        echo "$cls" > "$HUD_EXIT_FILE"
        rm -f "$HUD_ENTER_FILE"
        return 0
    fi
    rm -f "$flag" 2>/dev/null || true
    return 1
}

# ── main ─────────────────────────────────────────────────────────────────────

# 1. Active HUD?
check_hud "$VOL_HUD_FLAG"      "volume"     && exit 0
check_hud "$BRIGHT_HUD_FLAG"   "brightness" && exit 0
check_hud "$CHARGING_HUD_FLAG" "charging"   && exit 0

# 2. Exit animation (one poll after HUD ends)
if [[ -f "$HUD_EXIT_FILE" ]]; then
    cls=$(cat "$HUD_EXIT_FILE")
    rm -f "$HUD_EXIT_FILE"
    touch "$HUD_ENTER_FILE"  # set up clock-enter for next poll
    # Instantly trigger waybar re-poll right when exit animation (0.32s) completes
    (sleep 0.32 && pkill -SIGRTMIN+8 -u "$USER" waybar) &>/dev/null &
    # Emit last HUD state with "exiting" appended — CSS hud-exit animation fires
    printf '{"text":" ","class":"%s exiting"}\n' "$cls"
    exit 0
fi

# 3. Clock-enter animation (one poll after exit animation)
if [[ -f "$HUD_ENTER_FILE" ]]; then
    rm -f "$HUD_ENTER_FILE"
    emit_clock_enter
    exit 0
fi

# 4. Normal clock
emit_clock
