#!/usr/bin/env python3
import subprocess, sys, re, os

def run(cmd):
    try:
        return subprocess.check_output(cmd, stderr=subprocess.DEVNULL).decode("utf-8", "ignore")
    except:
        return ""

def is_powered():
    out = run(["bluetoothctl", "show"])
    return "Powered: yes" in out or "PowerState: on" in out

def get_devices():
    devs = []
    out = run(["bluetoothctl", "devices"])
    for line in out.strip().splitlines():
        m = re.match(r"^Device\s+([0-9A-Fa-f:]+)\s+(.*)$", line)
        if m:
            mac, name = m.group(1), m.group(2)
            info = run(["bluetoothctl", "info", mac])
            connected = "Connected: yes" in info
            devs.append({"mac": mac, "name": name, "connected": connected})
    return devs

powered = is_powered()

options = []
if not powered:
    options.append("󰂲  Turn ON Bluetooth")
else:
    options.append("󰂯  Turn OFF Bluetooth")
    options.append("󰂴  Scan for Devices")
    
    devs = get_devices()
    for d in devs:
        if d["connected"]:
            options.append(f"󰂱  {d['name']} (Connected)")
        else:
            options.append(f"󰂯  {d['name']} (Disconnected)")
    
    options.append("󰒓  Open Bluetooth Terminal")

menu_str = "\n".join(options)
try:
    proc = subprocess.Popen(["wofi", "--dmenu", "--width", "360", "--height", "260", "--prompt", "Bluetooth", "--cache-file", "/dev/null"],
                            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    sel, _ = proc.communicate(input=menu_str.encode("utf-8"))
    selected = sel.decode("utf-8").strip()
except Exception as e:
    sys.exit(0)

if not selected:
    sys.exit(0)

if "Turn ON Bluetooth" in selected:
    run(["rfkill", "unblock", "bluetooth"])
    run(["bluetoothctl", "power", "on"])
    subprocess.run(["notify-send", "Bluetooth", "Bluetooth Turned ON"])
elif "Turn OFF Bluetooth" in selected:
    run(["bluetoothctl", "power", "off"])
    run(["rfkill", "block", "bluetooth"])
    subprocess.run(["notify-send", "Bluetooth", "Bluetooth Turned OFF"])
elif "Scan for Devices" in selected:
    subprocess.Popen(["kitty", "-e", "bluetoothctl", "scan", "on"])
elif "Open Bluetooth Terminal" in selected:
    subprocess.Popen(["kitty", "-e", "bluetoothctl"])
elif "(Connected)" in selected:
    devs = get_devices()
    for d in devs:
        if d["name"] in selected:
            run(["bluetoothctl", "disconnect", d["mac"]])
            subprocess.run(["notify-send", "Bluetooth", f"Disconnected from {d['name']}"])
            break
elif "(Disconnected)" in selected:
    devs = get_devices()
    for d in devs:
        if d["name"] in selected:
            subprocess.run(["notify-send", "Bluetooth", f"Connecting to {d['name']}..."])
            out = run(["bluetoothctl", "connect", d["mac"]])
            subprocess.run(["notify-send", "Bluetooth", f"Connection command executed for {d['name']}"])
            break
