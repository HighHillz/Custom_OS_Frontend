#!/usr/bin/env python3
import glob, json, subprocess, os

ACTIVE_COLOR = "#3b82f6"
DIMMED_COLOR = "#3b82f64d"

_kbd_caps = False
_kbd_num  = False
try:
    _raw = subprocess.check_output(
        ["hyprctl", "devices", "-j"],
        stderr=subprocess.DEVNULL
    ).decode()
    _data = json.loads(_raw)
    for _kb in _data.get("keyboards", []):
        if _kb.get("main"):
            _kbd_caps = bool(_kb.get("capsLock"))
            _kbd_num  = bool(_kb.get("numLock"))
            break
except Exception:
    pass

def check_caps():
    return _kbd_caps

def check_num():
    return _kbd_num

def check_touchpad():
    try:
        with open("/tmp/touchpad_state") as f:
            return f.read().strip() == "true"
    except Exception:
        return True

def check_headphone():
    try:
        out = subprocess.check_output(
            ["amixer", "-c", "1", "cget", "numid=12"],
            stderr=subprocess.DEVNULL
        ).decode()
        return ": values=on" in out
    except Exception:
        return False

caps_active     = check_caps()
num_active      = check_num()
touchpad_active = check_touchpad()
hp_active       = check_headphone()

caps_color     = ACTIVE_COLOR if caps_active     else DIMMED_COLOR
num_color      = ACTIVE_COLOR if num_active      else DIMMED_COLOR
touchpad_color = ACTIVE_COLOR if touchpad_active else DIMMED_COLOR
hp_color       = ACTIVE_COLOR if hp_active       else DIMMED_COLOR

# Uniform icons with exact matching spacing
caps_icon     = f"<span foreground='{caps_color}'>⇪</span>"
num_icon      = f"<span foreground='{num_color}'>⇭</span>"
touchpad_icon = f"<span foreground='{touchpad_color}'>󰟸</span>"
hp_icon       = f"<span foreground='{hp_color}'>󰋋</span>"

# Equi-spaced icons inside the status block
text = f"{hp_icon}   {caps_icon}   {num_icon}   {touchpad_icon}"

caps_status     = "ON"        if caps_active     else "OFF"
num_status      = "ON"        if num_active      else "OFF"
touchpad_status = "Enabled"   if touchpad_active else "Disabled"
hp_status       = "Connected" if hp_active      else "Disconnected"

tooltip = (
    f"Headphones: {hp_status}\n"
    f"Caps Lock:  {caps_status}\n"
    f"Num Lock:   {num_status}\n"
    f"Touchpad:   {touchpad_status}"
)

print(json.dumps({"text": text, "tooltip": tooltip, "class": "status-module"}, ensure_ascii=False))
