-- Environment variables:
hl.env('XCURSOR_SIZE', '24')
hl.env('GDK_SCALE', '2')

hl.on('hyprland.start', function()
    hl.exec_cmd 'systemctl --user start hyprpolkitagent' -- Authentication agent.
    hl.exec_cmd 'wl-paste --watch cliphist store' -- Clipboard.
    hl.exec_cmd 'swaybg -i $XDG_CONFIG_HOME/hypr/wallpapers/pixel-pink-cloudy-moon.png' -- Wallpaper.
    hl.exec_cmd 'hypridle' -- Lock screen when idle.
    hl.exec_cmd 'sway-audio-idle-inhibit' -- Don't sleep while something is playing.
    hl.exec_cmd("bash -c 'sleep 10 && thunderbird'", { workspace = 'name:comms silent' }) -- Email client. Wait for a bit to avoid email connection errors.
    hl.exec_cmd('signal-desktop', { workspace = 'name:comms silent' }) -- Chat.
    hl.exec_cmd('obsidian', { workspace = 'name:obsidian silent' }) -- Note taking.
    hl.exec_cmd 'waybar' -- Status bar.
    hl.exec_cmd 'swaync' -- Notifications.
    hl.exec_cmd 'hyprsunset' -- Automatic blue light filter.
end)

-- Built-in display + external monitor:
hl.monitor { output = 'eDP-1', mode = 'preferred', position = '0x0', scale = 2 }
hl.monitor { output = 'DP-4', mode = 'preferred', position = '1440x-500', scale = 2 }

hl.config {
    input = {
        kb_layout = 'us,us',
        kb_variant = ',intl',
        sensitivity = -0.3,
        natural_scroll = true, -- macOS-like scrolling.
        touchpad = { natural_scroll = true },
    },
    general = {
        gaps_in = 2, -- Gaps between windows.
        gaps_out = 2, -- Gaps between windows and monitor edges.
        border_size = 2, -- Border size around windows.
        resize_on_border = true, -- Resize windows by dragging on the border.
        col = { active_border = 'rgb(d0b5f3)' }, -- Purple border for active windows.
    },
    ecosystem = {
        no_update_news = true, -- Disable the popup that shows up after an update.
        no_donation_nag = true, -- Disable the popup that asks for donations.
    },
    cursor = { inactive_timeout = 4 }, -- Hide cursor after 4 seconds of inactivity.
    decoration = {
        rounding = 5, -- Window border radius.
        blur = { enabled = false }, -- I don't use this.
    },
    misc = {
        disable_hyprland_logo = true, -- Disable the default anime background.
        -- Wake up with key/mouse activity.
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
    },
    xwayland = { force_zero_scaling = true }, -- Avoid blurry XWayland apps.
}

-- Smooth animations:
hl.curve('easeOut', { type = 'bezier', points = { { 0.2, 1 }, { 0.2, 1 } } })
hl.animation { leaf = 'windows', enabled = true, speed = 5, bezier = 'easeOut' }
hl.animation { leaf = 'windowsIn', enabled = true, speed = 5, bezier = 'default', style = 'popin' }
hl.animation { leaf = 'workspaces', enabled = true, speed = 6, bezier = 'default' }

require 'binds'
require 'window-rules'
