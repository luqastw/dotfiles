#!/bin/bash
# Toggle the dropdown scratchpad terminal (class "scratchterm").
# Spawns it if it isn't running yet, otherwise just shows/hides it.

class="scratchterm"

if ! i3-msg -t get_tree | grep -q "\"instance\":\"$class\""; then
    i3-msg "exec alacritty --class $class" >/dev/null
    # give the window time to map before the for_window rule + scratchpad show fire
    sleep 0.3
fi

i3-msg "[instance=\"$class\"] scratchpad show" >/dev/null
