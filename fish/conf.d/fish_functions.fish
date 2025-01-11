set -gx anime_girls_dir ~/scraped-images/anime_girls
set -gx last_query_file ~/scraped-images/.last_query
set -gx venv_path ~/scraped-images/venv
set -gx script_path ~/scraped-images/fetcher.py
set -gx current_image ~/scraped-images/current_anime_girl.png

function detect_terminal_support
    set -l term $TERM
    set -l terminal_program $TERM_PROGRAM

    set -l xdg_session_type $XDG_SESSION_TYPE
    
    if test -n "$GHOSTTY_RESOURCES_DIR"
        echo "kitty"
        return 0
    end

    if test -n "$KITTY_WINDOW_ID"
        echo "kitty"
        return 0
    end
    
    echo "ascii"
    return 0
end

function check_fastfetch_setup
    if not test -d $anime_girls_dir
        echo "Creating anime girls directory..."
        mkdir -p $anime_girls_dir
        return 1
    end

    if not test -d $venv_path
        echo "Virtual environment not found at $venv_path"
        return 1
    end

    if not test -f $script_path
        echo "Python script not found at $script_path"
        return 1
    end

    return 0
end

function display_image_with_fastfetch
    set -l image_path $argv[1]
    set -l protocol (detect_terminal_support)
    
    if test "$protocol" = "ascii"
        fastfetch --config neofetch.jsonc
    else
        fastfetch --kitty $image_path --config neofetch.jsonc
    end
end

function display_random_waifu
    set images $anime_girls_dir/*.png
    if test (count $images) -gt 0
        set random_image (random choice $images)
        if test -e $random_image
            display_image_with_fastfetch $random_image
        else
            echo "Selected image doesn't exist. Using default fastfetch output."
            fastfetch --config neofetch.jsonc
        end
    else
        echo "No images found in $anime_girls_dir. Using default fastfetch output."
        fastfetch --config neofetch.jsonc
    end
end

function display_current_waifu
    if test -e $current_image
        display_image_with_fastfetch $current_image
    else
        echo "Current image not found. Using default fastfetch output."
        fastfetch --config neofetch.jsonc
    end
end

function check_and_update_waifu
    if not check_fastfetch_setup
        echo "Fastfetch setup incomplete - using default output"
        fastfetch --config neofetch.jsonc
        return 1
    end

    set current_date (date +%Y-%m-%d)
    if test -f $last_query_file
        read -l last_date last_query < $last_query_file
        if test "$current_date" != "$last_date"
            $venv_path/bin/python $script_path --tag "$last_query" --force
            echo "$current_date $last_query" > $last_query_file
        end
    else
        $venv_path/bin/python $script_path --tag "1girl" --additional-tags "solo" --force
        echo "$current_date 1girl solo" > $last_query_file
    end
end

function waifu-update
    $venv_path/bin/python $script_path $argv
    set current_date (date +%Y-%m-%d)
    if test (count $argv) -gt 0
        set query_parts
        
        set i 1
        while test $i -le (count $argv)
            set arg $argv[$i]
            if string match -q -- "--*" $arg
                if contains -- $arg "--tag" "--character"
                    set i (math $i + 1)
                    if test $i -le (count $argv)
                        set -a query_parts $argv[$i]
                    end
                end
            else if not string match -q -- "--*" $argv[(math $i - 1)]
                set -a query_parts $arg
            end
            set i (math $i + 1)
        end
        
        if test (count $query_parts) -gt 0
            echo "$current_date $query_parts" > $last_query_file
        else
            echo "$current_date 1girl solo" > $last_query_file
        end
    else
        echo "$current_date 1girl solo" > $last_query_file
    end

    sleep 0.1
    display_current_waifu
end

function waifu-help
    echo "Usage:"
    echo "  waifu-refresh [query]  - Refresh the waifu image with an optional query."
    echo "  waifu-update [args...]  - Update the waifu image with the provided arguments."
    echo "  waifu-help              - Display this help message."
    echo ""
    echo "Parameters for waifu-refresh:"
    echo "  [query]                - Optional search query to fetch a specific waifu image."
    echo "                           If not provided, defaults to last used query."
    echo ""
    echo "Parameters for waifu-update:"
    echo "  [args...]              - Arguments for the waifu-update function"
    echo "      --force             - Force fetch a new image."
    echo "      --print-path        - Print the path of the current image."
    echo "      --tag <tag>         - Tag for the waifu image."
    echo "      --character <name>  - Specific character to search for."
    echo "      --negative-tags <tags> - Tags to exclude from the search."
    echo "      --no-bg-remove      - Disable background removal."
    echo "      --no-alpha-matting  - Disable alpha matting in background removal."
    echo "      --debug             - Show debug information."
end

complete -c waifu-refresh -s h -l help -d "Display help for the waifu-refresh command"
complete -c waifu-refresh -a "(commandline -ct)" -d "Search query for refresh"

complete -c waifu-update -s h -l help -d "Display help for the waifu-update command"
complete -c waifu-update -l force -d "Force fetch a new image"
complete -c waifu-update -l print-path -d "Print the path of the current image"
complete -c waifu-update -l tag -d "Tag for the waifu image"
complete -c waifu-update -l character -d "Specific character to search for"
complete -c waifu-update -l negative-tags -d "Tags to exclude from the search"
complete -c waifu-update -l no-bg-remove -d "Disable background removal"
complete -c waifu-update -l no-alpha-matting -d "Disable alpha matting in background removal"
complete -c waifu-update -l debug -d "Show debug information"
