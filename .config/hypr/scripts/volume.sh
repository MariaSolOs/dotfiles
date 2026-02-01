#!/usr/bin/env bash

# Change the volume according to the input flag.
if [[ "$1" == "--dec" ]]; then
    pamixer -d 5 --set-limit 100
elif [[ "$1" == "--inc" ]]; then
    pamixer -i 5 --set-limit 100
elif [[ "$1" == "--toggle-mut" ]]; then
    pamixer -t
fi
