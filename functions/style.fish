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
