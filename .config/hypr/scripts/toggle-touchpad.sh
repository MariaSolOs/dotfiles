#!/usr/bin/env bash

function toggletouchpad() {
	local setting='device:apple-internal-keyboard-/-trackpad-1:enabled'
	local settingfile='/tmp/toggle-touchpad-notification-id'

	if [ -f $settingfile ]; then
		notificationid=$(cat $settingfile)
	else
		notificationid=0
	fi

	# Check if the touchpad is enabled.
	local settingvalue
	settingvalue=$(hyprctl getoption $setting | rg 'int: 1')

	local icon message newsettingvalue
	if [ -z "$settingvalue" ]; then
		# The touchpad is disabled:
		icon='enabled'
		message='Enabling'
		newsettingvalue=1
	else
		# The touchpad is enabled:
		icon='disabled'
		message='Disabling'
		newsettingvalue=0
	fi

	# Notify and save the new ID.
	notificationid=$(notify-send -p -r "$notificationid" -i "touchpad-$icon-symbolic" -a "hyprland" "$message touchpad...")
	echo "$notificationid" >$settingfile

	# Change the Hyprland setting.
	hyprctl keyword $setting $newsettingvalue
}

toggletouchpad
