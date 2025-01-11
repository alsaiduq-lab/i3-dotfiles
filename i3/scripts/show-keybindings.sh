#!/bin/bash
i3-msg -t get_config | awk '/^bindsym/ {print $2 " = " substr($0, index($0,$3))}' | rofi -dmenu -i -p "Keybindings"
