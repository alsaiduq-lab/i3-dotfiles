#!/usr/bin/env python3
import i3ipc
import sys

def on_new_window(i3, e):
    if e.container.window_class == "Ghostty" and e.container.window_title == "centered-ghostty":
        e.container.command('floating enable')
        e.container.command('resize set 1200 800')
        e.container.command('move position center')
        sys.exit(0)

i3 = i3ipc.Connection()
i3.on('window::new', on_new_window)
i3.main()
