#!/bin/bash
# Bluetooth status block. Left-click toggles power, right-click opens blueman-manager.

export LANG=C

case "$BLOCK_BUTTON" in
    1)
        if bluetoothctl show | grep -q "Powered: yes"; then
            bluetoothctl power off >/dev/null
        else
            bluetoothctl power on >/dev/null
        fi
        sleep 1
        ;;
    3)
        blueman-manager &
        ;;
esac

if ! bluetoothctl show | grep -q "Powered: yes"; then
    echo "<span color='#6b5a42'>off</span>"
    exit 0
fi

dev=$(bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f3-)

if [ -n "$dev" ]; then
    echo "$dev"
else
    echo "<span color='#6b5a42'>on</span>"
fi
