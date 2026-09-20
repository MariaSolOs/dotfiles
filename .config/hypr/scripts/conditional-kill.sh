#!/usr/bin/env bash

# Close the window, except for some special apps.
hyprctl activewindow -j | jq -r .title | grep -E "Mozilla Thunderbird|Obsidian|Signal" || hyprctl dispatch 'hl.dsp.window.close()'
