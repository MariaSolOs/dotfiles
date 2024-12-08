#!/usr/bin/env bash

# Change the screen brightness according to the input flag.
if [[ "$1" == "--dec" ]]; then
    brightnessctl s 10%- -q
elif [[ "$1" == "--inc" ]]; then
    brightnessctl s +10% -q
fi
