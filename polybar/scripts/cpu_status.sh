#!/bin/bash

# Handle click actions
if [[ "$1" == "click" ]]; then
    case "$2" in
        "left")
            if command -v btop &> /dev/null; then
                if command -v i3-msg &> /dev/null; then
                    i3-msg exec "ghostty -e sh -c 'btop'" &
                else
                    setsid ghostty -e btop &
                fi
            else
                notify-send "System Monitor" "btop is not installed"
            fi
            ;;
        "right")
            # Show core details in notification
            cores_info=$(get_core_usage)
            dunstify -t 2000 "CPU Cores" "$cores_info"
            ;;
    esac
    exit 0
fi

get_core_usage() {
    local tooltip=""
    local cores=$(grep -c ^processor /proc/cpuinfo)
    
    # Get two samples of CPU stats
    local start=($(cat /proc/stat | grep "^cpu[0-9]"))
    sleep 0.1
    local end=($(cat /proc/stat | grep "^cpu[0-9]"))
    
    for ((i=0; i<$cores; i++)); do
        read -ra start_vals <<< "${start[$i]}"
        read -ra end_vals <<< "${end[$i]}"
        
        # Calculate CPU times
        local start_idle=${start_vals[4]}
        local end_idle=${end_vals[4]}
        
        local start_total=0
        local end_total=0
        
        # Sum up all times
        for ((j=1; j<${#start_vals[@]}; j++)); do
            start_total=$((start_total + ${start_vals[$j]}))
            end_total=$((end_total + ${end_vals[$j]}))
        done
        
        local total_diff=$((end_total - start_total))
        local idle_diff=$((end_idle - start_idle))
        
        # Calculate usage percentage
        if [ "$total_diff" -eq 0 ]; then
            usage="0.0"
        else
            usage=$(awk "BEGIN {printf \"%.1f\", (($total_diff-$idle_diff)/$total_diff)*100}")
        fi
        
        tooltip+="Core $i: ${usage}%\n"
    done
    
    echo "${tooltip%\\n}"
}

# Get overall CPU usage
cpu_usage=$(top -bn1 | grep "Cpu(s)" | \
       sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | \
       awk '{print 100 - $1}')

# Get CPU temperature
if [ -f "/sys/class/thermal/thermal_zone0/temp" ]; then
    cpu_temp=$(( $(cat /sys/class/thermal/thermal_zone0/temp) / 1000 ))
    if [ "$cpu_temp" -gt 80 ]; then
        echo "%{F#f7768e}${cpu_usage}% ${cpu_temp}°C%{F-}"
    else
        echo "${cpu_usage}% ${cpu_temp}°C"
    fi
else
    if [ "${cpu_usage%.*}" -gt 80 ]; then
        echo "%{F#f7768e}${cpu_usage}%%{F-}"
    else
        echo "${cpu_usage}%"
    fi
fi
