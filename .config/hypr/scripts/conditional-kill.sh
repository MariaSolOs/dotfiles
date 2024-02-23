#!/usr/bin/env bash

# Get the title of the active window.
# If it doesn't match the title of the Thunderbird Inbox, kill it.
hyprctl activewindow | rg 'title: Inbox - [^ ]+ - Mozilla Thunderbird' || hyprctl dispatch killactive
