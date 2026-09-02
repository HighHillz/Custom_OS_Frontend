#!/usr/bin/env bash
# media-lock.sh — called by hyprlock cmd[] labels
# Usage: media-lock.sh [title|sub]
#   title (default) — player icon + track/video title
#   sub             — creator/channel name (YouTube only)
#
# Priority: Spotify → YouTube (any browser MPRIS) → VLC
# Hyprlock strips the user DBus session, so we set it explicitly.

export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"

MODE="${1:-title}"   # "title" or "sub"

# ─── Colour palette ───────────────────────────────────────────────────────────
SPOTIFY_COLOR="#1DB954"   # Spotify green
YOUTUBE_COLOR="#ff4040"   # YouTube red
VLC_COLOR="#ffaa22"       # VLC yellow-orange

# ─── Helpers ──────────────────────────────────────────────────────────────────
pango_span() {
    local color="$1" text="$2"
    printf '<span foreground="%s">%s</span>\n' "$color" "$text"
}

url_decode() {
    printf '%b' "${1//%/\\x}"
}

# ─── Detect active player (priority: Spotify → YouTube → VLC) ─────────────────
detect_player() {
    # 1. Spotify
    local s
    s=$(playerctl -p spotify status 2>/dev/null)
    if [[ "$s" == "Playing" || "$s" == "Paused" ]]; then
        echo "spotify"; return
    fi

    # 2. YouTube — any active browser MPRIS instance
    # (Chromium doesn't expose xesam:url, so we treat any playing browser as YouTube)
    while IFS= read -r player; do
        local pstatus
        pstatus=$(playerctl -p "$player" status 2>/dev/null)
        if [[ "$pstatus" == "Playing" || "$pstatus" == "Paused" ]]; then
            echo "youtube:$player"; return
        fi
    done < <(playerctl --list-all 2>/dev/null | grep -Ei 'chromium|firefox|brave|google-chrome|edge')

    # 3. VLC
    local v
    v=$(playerctl -p vlc status 2>/dev/null)
    if [[ "$v" == "Playing" || "$v" == "Paused" ]]; then
        echo "vlc"; return
    fi

    echo "none"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
PLAYER=$(detect_player)

if [[ "$PLAYER" == "none" ]]; then
    echo ' '; exit 0
fi

# Resolve player handle, colour, and icon
if [[ "$PLAYER" == "spotify" ]]; then
    HANDLE="spotify"; COLOR="$SPOTIFY_COLOR"; ICON="󰓇"
elif [[ "$PLAYER" == youtube:* ]]; then
    HANDLE="${PLAYER#youtube:}"; COLOR="$YOUTUBE_COLOR"; ICON="󰗃"
else
    HANDLE="vlc"; COLOR="$VLC_COLOR"; ICON="󰕼"
fi

# ─── Sub-line: artist + album (Spotify) / creator (YouTube) ─────────────────
if [[ "$MODE" == "sub" ]]; then
    if [[ "$PLAYER" == "spotify" ]]; then
        ARTIST=$(playerctl -p spotify metadata artist 2>/dev/null)
        ALBUM=$(playerctl -p spotify metadata album 2>/dev/null)
        if [[ -n "$ARTIST" && -n "$ALBUM" ]]; then
            pango_span "$SPOTIFY_COLOR" "$ARTIST  ·  $ALBUM"
        elif [[ -n "$ARTIST" ]]; then
            pango_span "$SPOTIFY_COLOR" "$ARTIST"
        else
            echo ' '
        fi
    elif [[ "$PLAYER" == youtube:* ]]; then
        CREATOR=$(playerctl -p "$HANDLE" metadata artist 2>/dev/null)
        # Playlist name is not available via Chromium MPRIS
        if [[ -n "$CREATOR" ]]; then
            pango_span "$COLOR" "$CREATOR"
        else
            echo ' '
        fi
    else
        echo ' '   # VLC: no sub-line
    fi
    exit 0
fi

# ─── Title line ───────────────────────────────────────────────────────────────
if [[ "$PLAYER" == "vlc" ]]; then
    URL=$(playerctl -p vlc metadata xesam:url 2>/dev/null)
    if [[ "$URL" == file://* ]]; then
        RAW_BASENAME="${URL##*/}"
        DECODED=$(url_decode "$RAW_BASENAME")
        TITLE="${DECODED%.*}"
    else
        TITLE=$(playerctl -p vlc metadata title 2>/dev/null)
    fi
else
    TITLE=$(playerctl -p "$HANDLE" metadata title 2>/dev/null)
fi

if [[ -z "$TITLE" ]]; then
    echo ' '; exit 0
fi

pango_span "$COLOR" "$ICON  $TITLE"
