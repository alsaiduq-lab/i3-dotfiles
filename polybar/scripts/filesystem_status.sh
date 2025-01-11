#!/bin/bash

if [[ "$1" == "click" ]]; then
    if command -v thunar &> /dev/null; then
        if command -v i3-msg &> /dev/null; then
            i3-msg exec "thunar" &
        else
            thunar &
        fi
    else
        notify-send "File Manager" "Thunar is not installed"
    fi
    exit 0
fi

root_usage=$(df -h / | tail -n 1)
used_space=$(echo $root_usage | awk '{print $3}')
total_space=$(echo $root_usage | awk '{print $2}')
usage_percent=$(echo $root_usage | awk '{print $5}' | sed 's/%//')

if [ "$usage_percent" -gt 80 ]; then
    echo "%{F#f7768e}${used_space}/${total_space}%{F-}"
else
    echo "${used_space}/${total_space}"
fi

mount_status=$(mount | grep " / " | awk '{print $6}' | cut -d ',' -f1)
if [ "$mount_status" != "rw" ]; then
    echo "%{F#f7768e}WARNING: Root filesystem not mounted read-write%{F-}"
fi
