#!/bin/bash

# Opções
lock="Block"
logout="Exit"
suspend="Suspend"
reboot="Reboot"
shutdown="Shutdown"

if [ "$BLOCK_BUTTON" ]; then
  options="$lock\n$logout\n$suspend\n$reboot\n$shutdown"

  selected=$(echo -e "$options" | dmenu -i -p "System:" \
    -fn 'JetBrains Mono Nerd Font-10' \
    -nb '#0b0a0d' \
    -nf '#d5c9bc' \
    -sb '#4d5a8c' \
    -sf '#e8e0d6')

  case "$selected" in
  "$lock")
    i3lock
    ;;
  "$logout")
    i3-msg exit
    ;;
  "$suspend")
    systemctl suspend
    ;;
  "$reboot")
    systemctl reboot
    ;;
  "$shutdown")
    systemctl poweroff
    ;;
  esac
fi

echo "⏻"
echo "⏻"
echo "#e8e0d6"
