#!/usr/bin/env bash

decrease_volume() {
    pactl -- set-sink-volume 0 -10%
}

increase_volume() {
    pactl -- set-sink-volume 0 +10%
}

# Change the volume according to the input flag.
if [[ "$1" == "--dec" ]]; then
    decrease_volume
elif [[ "$1" == "--inc" ]]; then
    increase_volume
fi
