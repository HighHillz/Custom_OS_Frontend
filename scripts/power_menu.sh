#!/bin/bash

# Define the power menu options
entries="Lock\nSuspend\nReboot\nShutdown\nLogout"

# Use wofi to display the dmenu options
selected=$(echo -e $entries | wofi --width 250 --height 210 --dmenu --cache-file /dev/null | awk '{print tolower($1)}')

# Execute the selected command
case $selected in
  lock)
    hyprlock || swaylock || xdg-screensaver lock;;
  suspend)
    systemctl suspend;;
  reboot)
    systemctl reboot;;
  shutdown)
    systemctl poweroff;;
  logout)
    hyprctl dispatch exit;;
esac
