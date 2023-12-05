#!/usr/bin/env bash

# Script for checking if the active Hyprland window is in fullscreen mode.

check_fullscreen() {
	case $1 in
	activewindowv2* | fullscreen*)
		hyprctl activewindow -j | jq --raw-output .fullscreen
		;;
	createworkspace*)
		# When creating a new workspace, there's no window (so definitely not in fullscreen).
		echo false
		;;
	esac
}

socat -U - "UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do check_fullscreen "$line"; done
