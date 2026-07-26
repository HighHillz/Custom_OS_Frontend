#!/usr/bin/env bash
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
date +%s > /tmp/waybar_charging_hud
chmod a+rw /tmp/waybar_charging_hud
pkill -SIGRTMIN+8 -u high-hillz waybar
