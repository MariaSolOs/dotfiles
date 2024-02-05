#!/usr/bin/env bash

# Close the active window if it's not the email inbox.
hyprctl activewindow | rg 'title: Inbox - [^ ]+ - Mozilla Thunderbird' || hyprctl dispatch killactive
