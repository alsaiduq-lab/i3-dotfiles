#!/bin/bash

# Create a unique named pipe for this instance
PIPE="/tmp/cava.fifo"

# Clean up any existing pipe
[ -p "$PIPE" ] && rm "$PIPE"
mkfifo "$PIPE"

# Launch cava with your config
exec cava -p ~/.config/cava/config1
