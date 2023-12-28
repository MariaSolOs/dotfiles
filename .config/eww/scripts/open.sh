#!/usr/bin/env bash

# Start the eww daemon if it's not already running.
if [[ ! $(pidof eww) ]]; then
	eww daemon
fi

# Open the widgets.
eww open-many cal time
