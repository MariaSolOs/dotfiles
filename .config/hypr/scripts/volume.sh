#!/usr/bin/env bash

# Change the volume according to the input flag.
if [[ "$1" == "--dec" ]]; then
    pactl -- set-sink-volume 0 -10%
elif [[ "$1" == "--inc" ]]; then
    pactl -- set-sink-volume 0 +10%
fi
