#!/bin/bash

updates=$(pacman -Qu | wc -l)
if [ "$updates" -gt 0 ]; then
    dunstify -h string:x-dunst-stack-tag:updates "System Updates" "$updates updates available"
fi
