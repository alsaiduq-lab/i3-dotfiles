#!/bin/bash

killall -q polybar

while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

export DEFAULT_NETWORK_INTERFACE=$(ip route | grep '^default' | awk '{print $5}' | head -n1)

echo "---" | tee -a /tmp/polybar.log

polybar main 2>&1 | tee -a /tmp/polybar.log & disown
polybar bottom 2>&1 | tee -a /tmp/polybar.log & disown

echo "Both polybars launched..."
