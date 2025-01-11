#!/bin/bash

if command -v pamixer &> /dev/null; then
    volume=$(pamixer --get-volume)
    mute_status=$(pamixer --get-mute)
    if [ "$mute_status" = "true" ]; then
        echo "%{F#565f89}MUTE%{F-}"
    else
        if [ "$volume" -gt 66 ]; then
            icon="VOL"
        elif [ "$volume" -gt 33 ]; then
            icon="VOL"
        else
            icon="VOL"
        fi
        
        if [ "$volume" -gt 100 ]; then
            echo "%{F#f7768e}${icon} ${volume}%%{F-}"
        else
            echo "${icon} ${volume}%"
        fi
    fi
elif command -v amixer &> /dev/null; then
    volume=$(amixer get Master | grep -o "[0-9]*%" | head -1 | tr -d '%')
    mute_status=$(amixer get Master | grep -o "\[off\]" | head -1)
    if [ "$mute_status" = "[off]" ]; then
        echo "%{F#565f89}MUTE%{F-}"
    else
        if [ "$volume" -gt 66 ]; then
            icon="VOL"
        elif [ "$volume" -gt 33 ]; then
            icon="VOL"
        else
            icon="VOL"
        fi
        
        if [ "$volume" -gt 100 ]; then
            echo "%{F#f7768e}${icon} ${volume}%%{F-}"
        else
            echo "${icon} ${volume}%"
        fi
    fi
else
    echo "VOL N/A"
fi
