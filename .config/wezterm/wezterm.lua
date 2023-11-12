local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- Support for undercurl, etc.
config.term = 'wezterm'

-- Color theme.
local colors = {
    bg = '#0E1419',
    black = '#000000',
    grey = '#5C6370',
    lilac = '#BAA0E8',
}
config.color_scheme = 'Dracula (Official)'
config.colors = {
    background = colors.bg,
    tab_bar = {
        inactive_tab_edge = colors.black,
        active_tab = {
            bg_color = colors.lilac,
            fg_color = colors.black,
        },
        inactive_tab = {
            bg_color = colors.black,
            fg_color = colors.grey,
        },
        inactive_tab_hover = {
            bg_color = colors.bg,
            fg_color = colors.lilac,
        },
        new_tab = {
            bg_color = colors.bg,
            fg_color = colors.lilac,
        },
        new_tab_hover = {
            bg_color = colors.bg,
            fg_color = colors.lilac,
        },
    },
}

-- Inactive panes.
config.inactive_pane_hsb = {
    saturation = 0.6,
    brightness = 0.6,
}

-- Remove extra space.
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }

-- Native macOS fullscreen.
config.native_macos_fullscreen_mode = true

-- Cursor.
config.cursor_thickness = 2

-- Tab bar.
config.hide_tab_bar_if_only_one_tab = true
config.window_frame = {
    font = wezterm.font('Hasklug Nerd Font Mono', { weight = 'DemiBold' }),
    active_titlebar_bg = colors.bg,
    inactive_titlebar_bg = colors.bg,
}

-- Fonts.
config.font_size = 14
config.cell_width = 0.9
config.line_height = 1.2
config.font = wezterm.font('Hasklug Nerd Font Mono', { weight = 'Medium' })
config.font_rules = {
    {
        intensity = 'Bold',
        font = wezterm.font('Hasklug Nerd Font Mono', { weight = 'DemiBold' }),
    },
    {
        intensity = 'Bold',
        italic = true,
        font = wezterm.font('Hasklug Nerd Font Mono', { weight = 'DemiBold', style = 'Italic' }),
    },
    {
        italic = true,
        font = wezterm.font 'Cartograph CF Italic',
    },
}

-- Make underlines THICK.
config.underline_position = -6
config.underline_thickness = '250%'

-- Keybindings.
config.disable_default_key_bindings = true
config.keys = {
    { mods = 'CTRL|SHIFT', key = 'x', action = act.ActivateCopyMode },
    { mods = 'CTRL|SHIFT', key = 'Enter', action = act.ToggleFullScreen },
    { mods = 'CTRL|SHIFT', key = 'L', action = act.ShowDebugOverlay },
    { mods = 'CTRL|SHIFT', key = 'v', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { mods = 'CTRL|SHIFT', key = 's', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
    { mods = 'CTRL|SHIFT', key = 'LeftArrow', action = act.ActivatePaneDirection 'Left' },
    { mods = 'CTRL|SHIFT', key = 'RightArrow', action = act.ActivatePaneDirection 'Right' },
    { mods = 'CTRL|SHIFT', key = 'UpArrow', action = act.ActivatePaneDirection 'Up' },
    { mods = 'CTRL|SHIFT', key = 'DownArrow', action = act.ActivatePaneDirection 'Down' },
    { mods = 'SUPER', key = '1', action = act.ActivateTab(0) },
    { mods = 'SUPER', key = '2', action = act.ActivateTab(1) },
    { mods = 'SUPER', key = '3', action = act.ActivateTab(2) },
    { mods = 'SUPER', key = '4', action = act.ActivateTab(3) },
    { mods = 'SUPER', key = '5', action = act.ActivateTab(4) },
    { mods = 'SUPER', key = 'n', action = act.SpawnWindow },
    { mods = 'SUPER', key = 't', action = act.SpawnTab 'CurrentPaneDomain' },
    { mods = 'SUPER', key = 'w', action = act.CloseCurrentPane { confirm = true } },
    { mods = 'SUPER', key = 'f', action = act.Search 'CurrentSelectionOrEmptyString' },
    { mods = 'SUPER', key = 'c', action = act.CopyTo 'Clipboard' },
    { mods = 'SUPER', key = 'v', action = act.PasteFrom 'Clipboard' },
}

return config
