#!/bin/bash

if [[ "$1" == "click" ]]; then
    if command -v btop &> /dev/null; then
        if command -v i3-msg &> /dev/null; then
            i3-msg exec "ghostty -e sh -c 'btop'" &
        else
            setsid ghostty -e btop &
        fi
    else
        notify-send "System Monitor" "btop is not installed"
    fi
    exit 0
fi

memory_data=$(free -m | grep Mem)
total_mem=$(echo $memory_data | awk '{print $2}')
used_mem=$(echo $memory_data | awk '{print $3}')
free_mem=$(echo $memory_data | awk '{print $4}')
cached_mem=$(echo $memory_data | awk '{print $6}')
mem_percentage=$(( ($used_mem * 100) / $total_mem ))
actual_used=$(($used_mem - $cached_mem))
actual_percentage=$(( ($actual_used * 100) / $total_mem ))

if [ "$total_mem" -lt 1024 ]; then
    mem_display="${used_mem}MB/${total_mem}MB"
else
    total_mem_gb=$(($total_mem / 1024))
    used_mem_gb=$(($used_mem / 1024))
    if [ "$mem_percentage" -gt 90 ]; then
        total_mem_gb=$(echo "scale=1; $total_mem / 1024" | bc)
        used_mem_gb=$(echo "scale=1; $used_mem / 1024" | bc)
    fi
    mem_display="${used_mem_gb}GB/${total_mem_gb}GB"
fi

if [ "$mem_percentage" -gt 80 ]; then
    echo "%{F#f7768e}${mem_percentage}% ($mem_display)%{F-}"
else
    echo "${mem_percentage}% ($mem_display)"
fi
