#!/bin/bash
# Wifi status block. Left-click toggles radio, right-click opens nmtui for full management.

export LANG=C

case "$BLOCK_BUTTON" in
    1)
        if nmcli radio wifi | grep -q enabled; then
            nmcli radio wifi off
        else
            nmcli radio wifi on
        fi
        sleep 1
        ;;
    3)
        i3-msg exec -- "alacritty --class floatterm -e nmtui" >/dev/null
        ;;
esac

if ! nmcli radio wifi | grep -q enabled; then
    echo "<span color='#6b5a42'>off</span>"
    exit 0
fi

ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '$1=="yes"{print $2; exit}')

if [ -n "$ssid" ]; then
    echo "$ssid"
else
    echo "<span color='#6b5a42'>desconectado</span>"
fi
