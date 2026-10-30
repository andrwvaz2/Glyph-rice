#!/bin/bash
sleep 0.05

state=$(hyprctl devices -j | jq -r '[.keyboards[].capsLock] | any')

if [ "$state" = "true" ]; then
    for dev in /sys/class/leds/*::capslock; do
        [ -e "$dev" ] && brightnessctl --device="${dev##*/}" set 1 2>/dev/null || true
    done
    notify-send -h string:x-canonical-private-synchronous:caps_lock \
                -t 1500 -a "Teclado" -i keyboard \
                "Bloq Mayús" "ACTIVADO [A]"
else
    for dev in /sys/class/leds/*::capslock; do
        [ -e "$dev" ] && brightnessctl --device="${dev##*/}" set 0 2>/dev/null || true
    done
    notify-send -h string:x-canonical-private-synchronous:caps_lock \
                -t 1500 -a "Teclado" -i keyboard \
                "Bloq Mayús" "DESACTIVADO [a]"
fi
