#!/usr/bin/env bash

function toggletouchpad() {
	local setting='device:apple-internal-keyboard-/-trackpad-1:enabled'

	# Check if the touchpad is enabled.
	local settingvalue
	settingvalue=$(hyprctl getoption $setting | rg 'int: 1')

	if [ -z "$settingvalue" ]; then
		# The touchpad is disabled:
		notify-send -i 'touchpad-enabled-symbolic' 'Enabling touchpad...'
		hyprctl keyword $setting 1
	else
		# The touchpad is enabled:
		notify-send -i 'touchpad-disabled-symbolic' 'Disabling touchpad...'
		hyprctl keyword $setting 0
	fi
}

toggletouchpad
