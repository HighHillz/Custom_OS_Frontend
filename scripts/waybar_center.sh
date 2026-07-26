#!/usr/bin/env bash
# waybar_center.sh
# Normally shows the clock. When a volume or brightness key is pressed, temporarily
# shows a visual HUD for 3 seconds, then reverts.

VOL_HUD_FLAG="/tmp/waybar_volume_hud"
BRIGHT_HUD_FLAG="/tmp/waybar_brightness_hud"
CHARGING_HUD_FLAG="/tmp/waybar_charging_hud"
HUD_DURATION=3  # seconds

get_volume_json() {
    local raw vol muted icon bar filled i

    raw=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
    # raw is like "Volume: 0.72" or "Volume: 0.72 [MUTED]"

    if [[ "$raw" == *MUTED* ]]; then
        muted=1
    else
        muted=0
    fi

    # Extract float and convert to integer percent
    vol=$(echo "$raw" | awk '{printf "%d", $2 * 100}')
    [[ -z "$vol" ]] && vol=0

    if [[ "$muted" -eq 1 ]]; then
        printf '{"text":"🔇  Muted","class":"volume-hud muted"}'
    else
        local display_vol=$(( vol > 100 ? 100 : vol ))
        filled=$(( (display_vol + 9) / 10 ))
        bar=""
        for i in $(seq 1 10); do
            if [[ $i -le $filled ]]; then bar="${bar}▰"; else bar="${bar}▱"; fi
        done
        if   [[ $vol -ge 66 ]]; then icon="🔊"
        elif [[ $vol -ge 33 ]]; then icon="🔉"
        else                         icon="🔈"
        fi
        printf '{"text":"%s  %d%%   %s","class":"volume-hud"}' "$icon" "$vol" "$bar"
    fi
}

get_brightness_json() {
    local raw vol icon bar filled i

    raw=$(brightnessctl -m 2>/dev/null | awk -F, '{print $4}' | tr -d '%')
    vol=${raw:-0}

    local display_vol=$(( vol > 100 ? 100 : vol ))
    filled=$(( (display_vol + 9) / 10 ))
    bar=""
    for i in $(seq 1 10); do
        if [[ $i -le $filled ]]; then bar="${bar}▰"; else bar="${bar}▱"; fi
    done
    if   [[ $vol -ge 66 ]]; then icon=""
    elif [[ $vol -ge 33 ]]; then icon=""
    else                         icon=""
    fi
    printf '{"text":"%s  %d%%   %s","class":"brightness-hud"}' "$icon" "$vol" "$bar"
}

get_charging_json() {
    local capacity=""
    if [[ -f /sys/class/power_supply/BAT0/capacity ]]; then
        capacity="$(cat /sys/class/power_supply/BAT0/capacity)%"
    fi
    printf '{"text":"󱐋 Charging            %s","class":"charging-hud"}' "$capacity"
}

check_hud() {
    local flag_file=$1
    local type=$2
    if [[ -f "$flag_file" ]]; then
        local hud_time=$(cat "$flag_file" 2>/dev/null)
        local now=$(date +%s)
        local elapsed=$(( now - hud_time ))

        if [[ $elapsed -lt $HUD_DURATION ]]; then
            if [[ "$type" == "volume" ]]; then
                get_volume_json
            elif [[ "$type" == "brightness" ]]; then
                get_brightness_json
            elif [[ "$type" == "charging" ]]; then
                get_charging_json
            fi
            exit 0
        else
            rm -f "$flag_file"
        fi
    fi
}

check_hud "$VOL_HUD_FLAG" "volume"
check_hud "$BRIGHT_HUD_FLAG" "brightness"
check_hud "$CHARGING_HUD_FLAG" "charging"

# Default: show clock
printf '{"text":"  %s","class":"clock"}' "$(date '+%H:%M            %d %b %Y')"

