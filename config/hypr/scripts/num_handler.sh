#!/bin/bash

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/numlock_state"

# Leer estado actual (si no existe, por defecto es 1 porque numlock_by_default = true)
if [ ! -f "$STATE_FILE" ]; then
    current="1"
else
    current=$(cat "$STATE_FILE" 2>/dev/null)
    [ -z "$current" ] && current="1"
fi

if [ "$current" = "1" ]; then
    echo "0" > "$STATE_FILE"
    for dev in /sys/class/leds/*::numlock; do
        [ -e "$dev" ] && brightnessctl --device="${dev##*/}" set 0 2>/dev/null || true
    done
    notify-send -h string:x-canonical-private-synchronous:num_lock \
                -t 1500 -a "Teclado" -i keyboard \
                "Bloq Num" "DESACTIVADO [·]"
else
    echo "1" > "$STATE_FILE"
    for dev in /sys/class/leds/*::numlock; do
        [ -e "$dev" ] && brightnessctl --device="${dev##*/}" set 1 2>/dev/null || true
    done
    notify-send -h string:x-canonical-private-synchronous:num_lock \
                -t 1500 -a "Teclado" -i keyboard \
                "Bloq Num" "ACTIVADO [1]"
fi
