#!/usr/bin/env bash

# Take a screenshot, copying it to the clipboard and saving it to the screenshots directory.
grim -g "$(slurp -c B08BBB -w 1 -b B08BBB80)" - | wl-copy && wl-paste > "$XDG_PICTURES_DIR/Screenshots/$(date +%F_%T).png"
