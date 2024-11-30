#!/usr/bin/env bash

# Taken from https://github.com/hyprwm/Hyprland/issues/3558#issuecomment-1950015566.

if pgrep -x Hyprland >/dev/null; then
    # Use the regular dispatch command.
    hyprctl dispatch exit
    # Pause for 2 seconds.
    sleep 2
    # If still alive, be violent.
    if pgrep -x Hyprland >/dev/null; then
        killall -9 Hyprland
    fi
fi
