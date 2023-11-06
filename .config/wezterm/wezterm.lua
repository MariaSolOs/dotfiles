-- TODO: Add types (where is Folke pulling those from?)

local wezterm = require 'wezterm'

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
    active_titlebar_bg = '#0E1419',
    inactive_titlebar_bg = '#0E1419',
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

config.keys = {
    -- Scrollback.
    { key = 'k', mods = 'CTRL', action = wezterm.action.ScrollByPage(-0.5) },
    { key = 'j', mods = 'CTRL', action = wezterm.action.ScrollByPage(0.5) },
}

return config
