if status is-interactive
    # Commands to run in interactive sessions can go here


    # Test if the shell is interactive(before)


    # =============================================================================
    # PROFILE: Minimalist Neon HUD Dashboard
    # AUTHOR:  Alfin + Vei
    # PURPOSE: Asymmetric HUD layout with dynamic time-of-day states
    # =============================================================================

    function fish_greeting

        # STAGE 1: Time Parsing & Logic
        # -------------------------------------------------------------------------
        set hour (date +%H)
        set greeting_msg ""
        set greeting_color "yellow"

        # STAGE 2: Dynamic Greeting Configuration
        # -------------------------------------------------------------------------
        if test $hour -ge 0; and test $hour -lt 12
            set greeting_msg "Good morning, Alfin! ☕"
            set greeting_color "yellow"
        else if test $hour -ge 12; and test $hour -lt 18
            set greeting_msg "Good afternoon, Alfin! ☀️"
            set greeting_color "cyan"
        else
            set greeting_msg "Good evening, Alfin! 🌙"
            set greeting_color "magenta"
        end

        # STAGE 3: System Data Extraction
        # -------------------------------------------------------------------------
        set fedora_ver (string match -r 'VERSION_ID=\K.*' < /etc/os-release | string trim -c '"')

        # STAGE 4: UI Rendering (Asymmetric Accent Pillars)
        # -------------------------------------------------------------------------
        # echo ""
        echo (set_color ff69b4)"╭─── "(set_color $greeting_color)"$greeting_msg"(set_color normal)
        echo (set_color ff69b4)"│ "(set_color green)"  ● OS      "(set_color normal)": "(set_color 3C6EB4)"Fedora Workstation $fedora_ver"(set_color normal)
        echo (set_color ff69b4)"│ "(set_color green)"  ● Kernel  "(set_color normal)": "(set_color normal)(uname -r)
        echo (set_color ff69b4)"│ "(set_color green)"  ● Time    "(set_color normal)": "(set_color normal)(date +%H:%M:%S)
        echo (set_color ff69b4)"╰─────────────────────────────────────■"(set_color normal)
        # echo ""
    end

    # Run the dashboard when a new shell terminal opens
    # ? fish_greeting

    # =============================================================================
    # COMMAND OVERRIDES (Hooks)
    # =============================================================================

    function clear
        command clear
        fish_greeting
    end


    # #########################################################################
    # ### GLOBAL FILE OPENER & CONFIGURATION TOOLS                          ###
    # #########################################################################

    # Wrapper to open files using a specified editor or the system default
    function openwith
        set -l editor $argv[1]
        set -l filepath $argv[2]

        # If only 1 argument is provided, treat it as the file and use default $EDITOR
        if test -z "$filepath"
            set filepath $argv[1]
            set editor $EDITOR
            # Fall back to nano if $EDITOR is empty
            if test -z "$editor"
                set editor nano
            end
        end

        # Safety check: Ensure a file path was provided
        if test -z "$filepath"
            echo "Error: No file specified."
            echo "Usage: openwith [editor] [file_path]"
            return 1
        end

        # Validate and execute the chosen editor command
        switch $editor
            case gnome-text-editor gte gdit gedit
                gnome-text-editor $filepath
            case vi nano code micro
                $editor $filepath
            case '*'
                echo "Unknown editor: $editor"
                echo "Supported: gnome-text-editor (gte, gdit, gedit), vi, nano, code, micro"
                return 1
        end
    end

    # Quick shortcuts to edit primary configuration files
    function fishconf; openwith $argv[1] ~/.config/fish/config.fish; end
    function dnfconf;  openwith $argv[1] /etc/dnf/dnf.conf; end

    # Reload the current Fish shell configuration
    alias srcfish="source ~/.config/fish/config.fish; echo 'Fish config reloaded!'"

    # Shortcut for the universal file opener (Placed after function)
    alias ow="openwith"


    # #########################################################################
    # ### DISKS & PARTITIONS MANAGEMENT                                     ###
    # #########################################################################
    
    # Storage monitoring shortcuts
    alias thisdisks="lsblk -f"
    alias df="df -h"

    # Smart unmount that accepts a full path, device name, or media label
    function umountpartition
        set -l arg $argv[1]

        if string match -q "/dev/*" $arg
            sudo umount $arg
        else if string match -qr "^sd[a-z][0-9]+\$" $arg
            sudo umount "/dev/$arg"
        else
            sudo umount "/run/media/$USER/$arg"
        end
    end

    # Safely unmounts all active partitions of a drive and powers it down
    function ejectdisk
        set -l disk $argv[1]
        # Clean off any user-entered /dev/ prefix
        set disk (string replace -r "^/dev/" "" $disk)

        # Generate the partition match array safely
        set -l parts /dev/$disk[0-9]*

        for part in $parts
            # Ensure the partition string matches an actual block device that is mounted
            if test -e "$part"; and mount | grep -q "$part"
                echo "Unmounting $part..."
                sudo umount "$part"
            end
        end

        # Cut power to the physical drive
        echo "Powering off /dev/$disk..."
        sudo udisksctl power-off -b "/dev/$disk"
    end


    # #########################################################################
    # ### GIT SHORTCUTS                                                     ###
    # #########################################################################
    
    # Visualizes Git history as a clean, structured repository graph
    alias glog="git log --all --oneline --decorate --graph"
    alias graph="git log --all --oneline --decorate --graph"
    alias gitlog="git log --all --oneline --decorate --graph"
    
    alias ga="git add"
    alias gall="git add ."
    alias gs="git status"
    alias gb="git branch"
    alias gco="git checkout"
    alias gcm="git commit -m"
    alias gcam="git commit -am"
    alias gpl="git pull"
    alias gps="git push"
    alias gtg="git tag"
    alias gtgd="git tag -a"
    alias gd="git diff"
    alias gf="git fetch"

    # Function to add & show description for current/another
    function git --description 'Wrapper for git to add a desc command'
        if test "$argv[1]" = "desc"
            # Check for deletion flags (-d or --delete) anywhere in the arguments
            if contains -- "-d" $argv; or contains -- "--delete" $argv
                # Find if a specific branch was provided alongside the flag
                set branch ""
                
                # Safe way to loop arguments without slicing brackets:
                set all_args $argv
                set -e all_args[1] # Erase "desc" from the copy
                
                for arg in $all_args
                    if test "$arg" != "-d"; and test "$arg" != "--delete"
                        set branch $arg
                        break
                    end
                end

                # If no branch specified, use the current branch
                if test -z "$branch"
                    set branch (command git branch --show-current)
                end

                # Check if a description actually exists before trying to unset it
                if command git config branch.$branch.description > /dev/null
                    command git config --unset branch.$branch.description
                    echo "Description cleared for branch '$branch'."
                else
                    echo "No description found for branch '$branch'."
                end
                return
            end

            # --- Original logic for setting/reading ---
            set arg1 $argv[2]
            set arg2 $argv[3]

            if test -n "$arg1"; and command git branch --list $arg1 > /dev/null
                set is_branch 1
            else
                set is_branch 0
            end

            if test -n "$arg1"; and test -n "$arg2"
                set branch $arg1
                set message $arg2
                command git config branch.$branch.description "$message"
                echo "Description updated for branch '$branch'!"

            else if test -n "$arg1"; and test $is_branch -eq 0
                set branch (command git branch --show-current)
                set message $arg1
                command git config branch.$branch.description "$message"
                echo "Description updated for current branch '$branch'!"

            else
                if test -n "$arg1"
                    set branch $arg1
                else
                    set branch (command git branch --show-current)
                end
                
                command git config branch.$branch.description
            end
        else
            command git $argv
        end
    end

    # === How to use it? ===
    # - git desc "This is my current branch message"
    # - git desc dev_branch "This is the developer branch message"
    # - git desc
    # - git desc dev_branch
    # --- How to delete ---
    # git desc -d
    # git desc -d running
    # OR
    # git desc running -d

    # #########################################################################
    # ### SYSTEM, ENVIRONMENT & APPLICATION SHORTCUTS                       ###
    # #########################################################################
    alias dfwm="driftwm-session"

    alias rm="rm -i"
    
    alias ll="ls -l"
    alias la="ls -a"
    alias lla="ls -la"    
    
    # --- Update ---
    alias sdf="sudo dnf"
    alias sdnf="sudo dnf"

    alias sdnfup="sudo dnf up"
    alias sdnfupy="sudo dnf up -y"
    alias hardsdnfup="sudo dnf up --refresh"
    
    # --- Up ex. code cus tho large ex. the internet is fast tho
    alias sdnfupexc="sudo dnf up -x code"
    alias sdnfupexc0="sudo dnf up --exclude=code"

    # --- Terminal Basics ---
    alias c="clear"
    alias d="dnf"
    alias f="dnf"
    alias e="exit"
    alias x="exit"

    
    alias ds="dnf search"
    alias fs="dnf search"
    alias dfs="dnf search"

    alias sdg="sudo dnf group"

    alias dgl="dnf group list"
    alias dglh="dnf group list --hidden"
    alias dgl_h="dnf group list --hidden"

    alias fgl="dnf group list"
    alias fglh="dnf group list --hidden"
    alias fgl_h="dnf group list --hidden"

    alias dgfind="dnf group list --hidden | grep -i"
    alias fgfind="dnf group list --hidden | grep -i"

    alias dgif="dnf group info"
    alias fgif="dnf group info"

    alias sdfi="sudo dnf install"

    alias md="mkdir -v"    #--verbose
    alias mdp="mkdir -pv"    #--parents
    alias md_p="mkdir -pv"

    # --- GNOME Text Editor ---
    alias gte="gnome-text-editor"
    alias gdit="gnome-text-editor"
    alias gedit="gnome-text-editor"

    # --- FEDORA ASS ---
    alias deskports="rpm -qa | grep xdg-desktop-portal"

    # --- System & Settings Paths ---
    alias customcursor="echo /etc/dconf/db/local.d"
    alias defaultcursor="echo /usr/share/icons/default/"
    alias cursorupdate="sudo dconf update"
    alias networkmanager="echo /etc/NetworkManager/"

    # #########################################################################
    # ### DOCKER & DOCKER COMPOSE                                           ###
    # #########################################################################

    # --- Docker Desktop Management ---
    # Docker Desktop Start
    alias ddstart="docker desktop start"
    alias docdesstart="docker desktop start"
    alias hardocstart="systemctl --user start docker-desktop"
    # Docker Desktop Stop
    alias ddstop="docker desktop stop"
    alias docdestop="docker desktop stop"
    alias hardocstop="systemctl --user stop docker-desktop"
    # Docker Desktop Restart
    alias ddr="docker desktop restart"
    alias ddres="docker desktop restart"
    alias docdesres="docker desktop restart"
    alias dockerestart="docker desktop restart"
    alias hardocres="systemctl --user restart docker-desktop"
    alias hardockerestart="systemctl --user restart docker-desktop"

    # --- Docker Compose Core ---
    alias docker-compose="docker compose"
    alias dc="docker compose"
    # Docker Compose Up
    alias dcu="docker compose up"
    alias dcud="docker compose up -d"
    alias dcu_d="docker compose up -d"
    # Docker Compose Down
    alias dcd="docker compose down"
    alias dcdd="docker compose down && rm -f ./mysql_data/mysql.sock"
    alias dcdev="docker compose down && rm -f ./mysql_data/mysql.sock"
    alias dcdnrm="docker compose down && rm -f ./mysql_data/mysql.sock"
    alias hardcdv="docker compose down -v"
    alias hardcd_v="docker compose down -v"


    # #########################################################################
    # ### YAZI WRAPPER                                                      ###
    # #########################################################################
    
    # Keeps your shell terminal synced with the directory you last visited in Yazi
    function y
        set -l tmp (mktemp -t "yazi-cwd.XXXXXX")
        command yazi $argv --cwd-file="$tmp"
        
        if test -s "$tmp"
            set -l cwd (cat "$tmp")
            if test "$cwd" != "$PWD"; and test -d "$cwd"
                builtin cd -- "$cwd"
            end
        end
        command rm -f -- "$tmp"
    end


end

# #########################################################################
# ### GEMINI	                                                        ###
# #########################################################################

# --- GIT PROMPT GLOBAL CONFIGURATION ---
set -g __fish_git_prompt_show_informative_status 1
set -g __fish_git_prompt_showdirtystate 1
set -g __fish_git_prompt_showuntrackedfiles 1
set -g __fish_git_prompt_showupstream "informative"
set -g VIRTUAL_ENV_DISABLE_PROMPT 1

# --- MAIN PROMPT FUNCTION ---
function fish_prompt
    # Save command status immediately for the smart arrow
    set -l last_status $status

    # Set up smart arrow colors
    if test $last_status -eq 0
        set_color ff69b4
    else
        set_color red
    end
    echo -n "╭─ "
    set_color normal

    # Username & Hostname
    set -l user_host "$USER@$hostname"
    if test "$USER" = "root"
        set_color red
    else
        set_color b573ff
    end
    echo -n "$USER"
    set_color 3c6eb4
    echo -n "@"
    set_color blue
    echo -n "$hostname "

    # --- 1. SSH SESSION INDICATOR ---
    set -l ssh_info ""
    if set -q SSH_TTY; or set -q SSH_CLIENT; or set -q SSH_CONNECTION
        set_color brred
        echo -n "🌐[SSH] "
        set_color normal
        set ssh_info "🌐[SSH] " 
    end

    # --- ADJUST YOUR CUSTOM LIMITS HERE ---
    set -l max_folder_length 25  
    set -l min_slice_size 11     
    
    # --- STARTUP FIX ---
    set -l term_width $COLUMNS
    if test -z "$term_width" -o "$term_width" -eq 0
        set term_width 80
    end

    # Flags and setup
    set -l force_line_break 0
    set -l force_third_line 0
    set -l real_pwd (prompt_pwd)
    set -l short_pwd $real_pwd
    set -l current_folder (basename (pwd))
    set -l folder_len (string length "$current_folder")

    # Fetch Git details early
    set -l git_info (fish_git_prompt)

    # --- 2. AUTOMATIC PYTHON VENV & FILE DETECTOR ---
    set -l venv_info ""
    if set -q VIRTUAL_ENV
        # Active environment variable takes precedence
        set venv_info " 🐍("(basename "$VIRTUAL_ENV")")"
    else
        # Safely test if there's at least one .py file or project indicator
        # using a hidden glob evaluation that won't echo errors
        set -l has_py (string match -r '\.py$' (ls -A 2>/dev/null))
        if test -n "$has_py"; or test -f requirements.txt; or test -d .venv
            set venv_info " 🐍(py)"
        end
    end

    # --- 3. AUTOMATIC NODE.JS DETECTOR (GREEN CIRCLE) ---
    set -l node_info ""
    if test -f package.json
        if type -q node
            set node_info " 🟢 "(node -v)
        end
    end

    # --- 4. AUTOMATIC DOCKER CONTEXT & FILE DETECTOR ---
    set -l docker_info ""
    if set -q DOCKER_CONTEXT
        # Active environment variable takes precedence
        set docker_info " 🐳($DOCKER_CONTEXT)"
    else if test -f Dockerfile; or test -f docker-compose.yml; or test -f docker-compose.yaml
        # Fallback to file detection if inside a Docker project
        set docker_info " 🐳(docker)"
    end

    # --- 5. EXECUTION BENCHMARK TIMER ---
    set -l timer_info ""
    if test -n "$CMD_DURATION"; and test $CMD_DURATION -gt 2000
        set -l duration_seconds (math -s2 "$CMD_DURATION / 1000")
        set timer_info " "(set_color ffb300)"⏱️ "$duration_seconds"s"(set_color normal)
    end

    # Combine all environmental badges to measure available space dynamically
    set -l environmental_badges "$git_info$venv_info$node_info$docker_info$timer_info"
    
    # Strip color codes using regex replacement
    set -l clean_badges (string replace -ra '\x1b\[[0-9;]*[mK]' '' "$environmental_badges")
    set -l clean_ssh (string replace -ra '\x1b\[[0-9;]*[mK]' '' "$ssh_info")

    # Calculate exactly how much space everything ELSE takes up on line 1
    set -l user_host_len (string length "$user_host")
    set -l ssh_len (string length "$clean_ssh")
    
    # Total fixed characters on line 1
    set -l fixed_len (math $ssh_len + $user_host_len + 4 + 7 + (string length "$clean_badges"))
    set -l max_folder_space (math $term_width - $fixed_len)

    # --- LINE LAYOUT DETERMINATION ---
    set -l total_prompt_len (math (string length "$real_pwd") + $fixed_len)

    if test $total_prompt_len -le $term_width
        set short_pwd $real_pwd
        set force_line_break 0
        set force_third_line 0
    else
        set force_line_break 1

        if test $folder_len -gt $max_folder_length; or test $folder_len -gt $max_folder_space
            set -l slice_size (math --scale=0 "($max_folder_space - 3) / 2")
            if test $slice_size -lt $min_slice_size; set slice_size $min_slice_size; end
        end

        # --- PATH PROCESSING FOR LINE 2 ---
        if test $folder_len -gt $max_folder_length
            set -l l2_slice (math --scale=0 "($term_width - $user_host_len - $ssh_len - 4) / 2")
            if test $l2_slice -lt $min_slice_size; set l2_slice $min_slice_size; end
            
            set -l start_part (string sub -l $l2_slice -- "$current_folder")
            set -l end_part (string sub -s -$l2_slice -- "$current_folder")
            set short_pwd (string match -q "~*" $real_pwd; and echo "~"; or echo " ")/.../"$start_part...$end_part"
        else
            if string match -q "*/*/*" $real_pwd
                set -l base_dir (string split -m 1 / $real_pwd)[1]
                set short_pwd "$base_dir/.../$current_folder"
            end
        end

        # --- RESPONSIVE 3-LINE CHECK ---
        if test -n "$clean_badges"
            set -l clean_short_pwd (string replace -ra '\x1b\[[0-9;]*[mK]' '' "$short_pwd")
            set -l line2_total_content_len (math (string length "$clean_short_pwd") + 4 + (string length "$clean_badges") + 4)
            
            if test $line2_total_content_len -ge $term_width
                set force_third_line 1
            end
        end
    end

    # --- PRINT THE PROMPT ---
    if test $force_line_break -eq 1
        echo ""
        if test $last_status -eq 0; set_color ff69b4; else; set_color red; end
        echo -n "│  "
        set_color normal
    end

    # Print Working Directory
    set_color cyan
    echo -n $short_pwd
    set_color normal

    # Print badges on line 3 if layout is forced, otherwise keep them on line 2
    if test $force_third_line -eq 1
        echo ""
        if test $last_status -eq 0; set_color ff69b4; else; set_color red; end
        echo -n "│ "  
        set_color normal
    end

    # Print Git features
    set_color bryellow
    echo -n $git_info
    set_color normal

    # Print Python Venv features
    if test -n "$venv_info"
        set_color yellow
        echo -n $venv_info
        set_color normal
    end

    # Print Node.js features
    if test -n "$node_info"
        set_color green
        echo -n $node_info
        set_color normal
    end

    # Print Docker features
    if test -n "$docker_info"
        set_color 74b9ff
        echo -n $docker_info
        set_color normal
    end

    # Print Execution Timer
    if test -n "$timer_info"
        set_color brblack
        echo -n $timer_info
        set_color normal
    end

    # Final line break logic
    echo ""
    
    # --- SMART ARROW COMMAND LINE ---
    if test $last_status -eq 0; set_color ff69b4; else; set_color red; end
    echo -n "╰─❯ "
    set_color normal
end

# Created by `pipx` on 2026-08-08 15:30:09
set PATH $PATH /home/wolfei/.local/bin
