#!/usr/bin/env bash

# Take a screenshot, copying it to the clipboard and saving it to the screenshots directory.
grim -g "$(slurp -c B08BBB -w 1 -b B08BBB80)" - | wl-copy && wl-paste >"$GRIM_DEFAULT_DIR/$(date +%F_%T).png"
