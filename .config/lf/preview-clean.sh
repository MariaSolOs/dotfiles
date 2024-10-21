#!/usr/bin/env bash

# Cleaner script.
# I don't really know what it does, I just took it from https://github.com/gokcehan/lf/wiki/Previews#with-kitty-and-pistol.
kitty +kitten icat --clear --stdin no --silent --transfer-mode file </dev/null >/dev/tty
