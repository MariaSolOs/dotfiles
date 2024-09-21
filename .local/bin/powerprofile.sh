#!/usr/bin/env bash

# If true, the laptop isn't charging, so save battery. 
if [ "$1" = "true" ]; then
    powerprofilesctl set power-saver
    brightnessctl -s set 40
fi

if [ "$1" = "false" ]; then
    powerprofilesctl set balanced
    brightnessctl -r
fi
