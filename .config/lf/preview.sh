#!/usr/bin/env bash

# If the file is an image, use kitty to display it.
if [[ "$(file -Lb --mime-type "$1")" =~ ^image ]]; then
	kitty +kitten icat --silent --stdin no --transfer-mode file --place "${2}x${3}@${4}x${5}" "$1" </dev/null >/dev/tty
	exit 1
fi

# Else fallback to bat.
bat --color=always --theme="Dracula" --style="header,numbers,snip" "$1"
