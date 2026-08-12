#!/usr/bin/env bash
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
# Write timestamp with world-rw permissions so user process can delete it later
install -m 666 /dev/null /tmp/waybar_charging_hud
date +%s > /tmp/waybar_charging_hud
pkill -SIGRTMIN+8 -u high-hillz waybar
