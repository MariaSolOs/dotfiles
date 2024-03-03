#!/usr/bin/env bash

function toggletouchpad() {
	# Disable shell expansion.
	# shellcheck disable=SC2016
	local setting='$TOUCHPAD_ENABLED'

	# For storing the notification ID and current value.
	local statusfile='/tmp/toggle-touchpad-status'

	# Read the current status (if any).
	local notificationid=0
	local enabled=true
	if [ -f $statusfile ]; then
		notificationid=$(cat $statusfile | cut -d ' ' -f 1)
		enabled=$(cat $statusfile | cut -d ' ' -f 2)
	fi

	local icon message
	if [ "$enabled" == true ]; then
		icon='disabled'
		message='Disabling'
		enabled=false
	else
		icon='enabled'
		message='Enabling'
		enabled=true
	fi

	# Notify and save the new status.
	notificationid=$(notify-send -p -r "$notificationid" -i "touchpad-$icon-symbolic" -a "hyprland" "$message touchpad...")
	echo "$notificationid $enabled" >$statusfile

	# Change the Hyprland setting.
	hyprctl keyword $setting $enabled -r
}

toggletouchpad
