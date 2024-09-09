#!/usr/bin/env bash

# Close the window, except for Thunderbird and Obsidian.
hyprctl activewindow -j | jq -r .title | grep -E "Mozilla Thunderbird|Obsidian" || hyprctl dispatch killactive
