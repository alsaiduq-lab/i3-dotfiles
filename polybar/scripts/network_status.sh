#!/bin/bash
if command -v nmcli &> /dev/null; then
    connection_info=$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION dev status | head -n1)
    device=$(echo "$connection_info" | cut -d':' -f1)
    conn_type=$(echo "$connection_info" | cut -d':' -f2)
    state=$(echo "$connection_info" | cut -d':' -f3)
    name=$(echo "$connection_info" | cut -d':' -f4)
    
    if [ "$state" = "connected" ]; then
        if [ "$conn_type" = "wifi" ]; then
            strength=$(nmcli -f IN-USE,SIGNAL dev wifi | grep "^*" | awk '{print $2}')
            if [ "$strength" -gt 66 ]; then
                icon="直"
            elif [ "$strength" -gt 33 ]; then
                icon="睊"
            else
                icon="睊"
            fi
            echo "${icon} ${name} (${strength}%)"
        elif [ "$conn_type" = "ethernet" ]; then
            echo " ${name}"
        fi
    else
        echo "%{F#565f89}睊 disconnected%{F-}"
    fi
else
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo " connected"
    else
        echo "%{F#565f89}睊 disconnected%{F-}"
    fi
fi
