#!/usr/bin/env bash

function keyboardbacklight() {
	local device='kbd_backlight'

	# Get the current brightness value.
	local current
	current=$(brightnessctl --device=$device get)

	# Set the new brightness value, increasing it by ~25%.
	brightnessctl --device=$device set $(((current + 64) % 256))
}

keyboardbacklight
