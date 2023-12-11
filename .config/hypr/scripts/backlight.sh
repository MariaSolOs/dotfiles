#!/usr/bin/env bash

notify_backlight() {
	# Divide the current brightness by the maximum and multiply by 100 to get a percentage.
	local light
	light=$(printf "%.0f\n" $((100 * $(brightnessctl g) / $(brightnessctl m))))

	dunstify -a "Backlight" -h string:x-dunst-stack-tag:backlight -h int:value:"$light" ""
}

if [[ "$1" == "--inc" ]]; then
	brightnessctl s +5%
elif [[ "$1" == "--dec" ]]; then
	brightnessctl s 5%-
else
	echo "Usage: backlight [--inc|--dec]"
	exit 1
fi

notify_backlight
