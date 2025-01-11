#!/bin/bash

if [[ "$1" == "click" ]]; then
    if command -v nvtop &> /dev/null; then
        if command -v i3-msg &> /dev/null; then
            i3-msg exec "ghostty -e sh -c 'nvtop'" &
        else
            setsid ghostty -e nvtop &
        fi
    else
        notify-send "GPU Monitor" "nvtop is not installed"
    fi
    exit 0
fi

gpu_usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)
gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)
gpu_memory=$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits)
if [ $? -ne 0 ] || [ -z "$gpu_usage" ]; then
    echo "N/A"
    exit 1
fi

mem_used=$(echo "$gpu_memory" | cut -d',' -f1 | tr -d ' ')
mem_total=$(echo "$gpu_memory" | cut -d',' -f2 | tr -d ' ')
mem_used_gb=$(echo "scale=1; $mem_used / 1024" | bc)
mem_total_gb=$(echo "scale=1; $mem_total / 1024" | bc)

if (( $(echo "$mem_used_gb < 1" | bc -l) )); then
    mem_used_mb=$mem_used
    if [ "$gpu_usage" -gt 80 ]; then
        echo "${gpu_usage}% (${mem_used_mb}MB) (${gpu_temp}°C)"
    else
        echo "${gpu_usage}% (${mem_used_mb}MB) (${gpu_temp}°C)"
    fi
else
    if [ "$gpu_usage" -gt 80 ]; then
        echo "${gpu_usage}% (${mem_used_gb}GB) (${gpu_temp}°C)"
    else
        echo "${gpu_usage}% (${mem_used_gb}GB) (${gpu_temp}°C)"
    fi
fi
