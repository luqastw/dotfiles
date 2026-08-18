#!/bin/bash
# System power menu. Uses rofi -dmenu; picks up color scheme from ~/.config/rofi/config.rasi.
# Two trigger paths: i3blocks calls this on click with $BLOCK_BUTTON set; polybar's
# click-left has no such env var, so it passes an explicit "menu" argument instead.

lock="Lock"
logout="Exit"
suspend="Suspend"
reboot="Reboot"
shutdown="Shutdown"

if [ "$BLOCK_BUTTON" ] || [ "$1" = "menu" ]; then
    options="$lock\n$logout\n$suspend\n$reboot\n$shutdown"
    selected=$(echo -e "$options" | rofi -dmenu -i -p "System:")

    case "$selected" in
        "$lock")     i3lock ;;
        "$logout")   i3-msg exit ;;
        "$suspend")  systemctl suspend ;;
        "$reboot")   systemctl reboot ;;
        "$shutdown") systemctl poweroff ;;
    esac
fi

echo "⏻"
echo "⏻"
echo "#e4d3b0"
