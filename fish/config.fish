# Hide welcome message & ensure we are reporting fish as shell
set fish_greeting
set VIRTUAL_ENV_DISABLE_PROMPT "1"
set -xU MANPAGER "sh -c 'col -bx | bat -l man -p'"
set -xU MANROFFOPT "-c"

## Environment setup
# Apply .profile: use this to put fish compatible .profile stuff in
if test -f ~/.fish_profile
  source ~/.fish_profile
end

# Load environment variables and API keys
if test -f ~/.config/fish/envs.fish
    source ~/.config/fish/envs.fish
end

# Add ~/.local/bin to PATH
if test -d ~/.local/bin
    if not contains -- ~/.local/bin $PATH
        set -p PATH ~/.local/bin
    end
end

# Add depot_tools to PATH
if test -d ~/Applications/depot_tools
    if not contains -- ~/Applications/depot_tools $PATH
        set -p PATH ~/Applications/depot_tools
    end
end

# Export variable need for qt-theme
if type "qtile" >> /dev/null 2>&1
   set -x QT_QPA_PLATFORMTHEME "qt5ct"
end

# Set settings for https://github.com/franciscolourenco/done
set -U __done_min_cmd_duration 10000
set -U __done_notification_urgency_level low

## Functions
# Functions needed for !! and !$ https://github.com/oh-my-fish/plugin-bang-bang
function __history_previous_command
  switch (commandline -t)
  case "!"
    commandline -t $history[1]; commandline -f repaint
  case "*"
    commandline -i !
  end
end

function __history_previous_command_arguments
  switch (commandline -t)
  case "!"
    commandline -t ""
    commandline -f history-token-search-backward
  case "*"
    commandline -i '$'
  end
end

if [ "$fish_key_bindings" = fish_vi_key_bindings ];
  bind -Minsert ! __history_previous_command
  bind -Minsert '$' __history_previous_command_arguments
else
  bind ! __history_previous_command
  bind '$' __history_previous_command_arguments
end

# Fish command history
function history
    builtin history --show-time='%F %T '
end

function backup --argument filename
    cp $filename $filename.bak
end

# Copy DIR1 DIR2
function copy
    set count (count $argv | tr -d \n)
    if test "$count" = 2; and test -d "$argv[1]"
	set from (echo $argv[1] | string trim --right --chars=/)
	set to (echo $argv[2])
        command cp -r $from $to
    else
        command cp $argv
    end
end

# Cleanup local orphaned packages
function cleanup
    while pacman -Qdtq
        sudo pacman -R (pacman -Qdtq)
    end
end

# Replace ls with eza
alias ls 'eza -al --color=always --group-directories-first --icons' # preferred listing

alias cat 'bat --style header --style snip --style changes --style header'
if not test -x /usr/bin/yay; and test -x /usr/bin/paru
    alias yay 'paru'
end

# Common use
alias .. 'cd ..'
alias ... 'cd ../..'
alias .... 'cd ../../..'
alias ..... 'cd ../../../..'
alias ...... 'cd ../../../../..'
alias big 'expac -H M "%m\t%n" | sort -h | nl'     # Sort installed packages according to size in MB
alias dir 'dir --color=auto'
alias gitpkg 'pacman -Q | grep -i "\-git" | wc -l'
alias grep 'ugrep --color=auto'
alias egrep 'ugrep -E --color=auto'
alias fgrep 'ugrep -F --color=auto'
alias ip 'ip -color'
alias untar 'tar -zxvf '
alias vdir 'vdir --color=auto'
alias wget 'wget -c '

# Get fastest mirrors
alias mirror 'sudo reflector -f 30 -l 30 --number 10 --verbose --save /etc/pacman.d/mirrorlist'
alias mirrora 'sudo reflector --latest 50 --number 20 --sort age --save /etc/pacman.d/mirrorlist'
alias mirrord 'sudo reflector --latest 50 --number 20 --sort delay --save /etc/pacman.d/mirrorlist'
alias mirrors 'sudo reflector --latest 50 --number 20 --sort score --save /etc/pacman.d/mirrorlist'

# Get the error messages from journalctl
alias journal 'journalctl -p 3 -xb'

# Recent installed packages
alias rip 'expac --timefmt="%Y-%m-%d %T" "%l\t%n %v" | sort | tail -200 | nl'

## PATH setup
set -x PATH $HOME/.cargo/bin $PATH
set -gx PATH /home/cobray/.local/bin $PATH

set -Ux PYENV_ROOT $HOME/.pyenv
set -Ux PATH $PYENV_ROOT/bin $PATH

if status is-interactive
    pyenv init --path | source
    pyenv init - | source
end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

set -gx LUA_PATH "$HOME/.luarocks/share/lua/5.1/?.lua;$HOME/.luarocks/share/lua/5.1/?/init.lua;;"
set -gx LUA_CPATH "$HOME/.luarocks/lib/lua/5.1/?.so;;"

# Initialize starship prompt
if status is-interactive
    starship init fish | source
end

if status --is-interactive
    check_and_update_waifu
    display_random_waifu
end
