#!/usr/bin/env bash

notify_backlight() {
	# Divide the current brightness by the maximum and multiply by 100 to get a percentage.
	local light=$(printf "%.0f\n" $((100 * $(brightnessctl g) / $(brightnessctl m))))
	dunstify -a "Backlight" -h string:x-dunst-stack-tag:backlight -h int:value:"$light" ""
}

# Increase screen brightness.
inc_backlight() {
	brightnessctl s +5%
}

# Decrease screen brightness.
dec_backlight() {
	brightnessctl s 5%-
}

if [[ "$1" == "--inc" ]]; then
	inc_backlight
elif [[ "$1" == "--dec" ]]; then
	dec_backlight
else
	echo "Usage: backlight [--inc|--dec]"
	exit 1
fi

notify_backlight
