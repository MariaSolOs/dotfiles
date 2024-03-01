local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- TODO: Remove this when https://github.com/wez/wezterm/issues/5067 is fixed.
config.enable_wayland = false

-- Support for undercurl, etc.
config.term = 'wezterm'

-- Color theme.
local colors = {
    bg = '#0E1419',
    black = '#000000',
    dark_lilac = '#6D5978',
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
            fg_color = colors.dark_lilac,
        },
        inactive_tab_hover = {
            bg_color = colors.black,
            fg_color = colors.lilac,
        },
        new_tab = {
            bg_color = colors.bg,
            fg_color = colors.lilac,
        },
        new_tab_hover = {
            bg_color = colors.lilac,
            fg_color = colors.black,
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

-- Cursor.
config.cursor_thickness = 2

-- Tab bar.
config.hide_tab_bar_if_only_one_tab = true
config.window_frame = {
    font = wezterm.font('Hasklug Nerd Font Mono', { weight = 'DemiBold' }),
    font_size = config.enable_wayland and 9 or 18,
    active_titlebar_bg = colors.bg,
    inactive_titlebar_bg = colors.bg,
}

-- Fonts.
config.font_size = config.enable_wayland and 10 or 20
config.cell_width = 0.9
config.line_height = config.enable_wayland and 1.2 or 1.25
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

-- Disable automatic update notifications (I do this often anyway).
config.check_for_updates = false

-- Keybindings.
config.disable_default_key_bindings = true
local mods = 'ALT|SHIFT'
config.keys = {
    { mods = mods, key = 'x', action = act.ActivateCopyMode },
    { mods = mods, key = 'd', action = act.ShowDebugOverlay },
    { mods = mods, key = 'v', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { mods = mods, key = 's', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
    { mods = mods, key = 'h', action = act.ActivatePaneDirection 'Left' },
    { mods = mods, key = 'l', action = act.ActivatePaneDirection 'Right' },
    { mods = mods, key = 'k', action = act.ActivatePaneDirection 'Up' },
    { mods = mods, key = 'j', action = act.ActivatePaneDirection 'Down' },
    { mods = mods, key = 't', action = act.SpawnTab 'CurrentPaneDomain' },
    { mods = mods, key = 'q', action = act.CloseCurrentPane { confirm = true } },
    { mods = mods, key = 'y', action = act.CopyTo 'Clipboard' },
    { mods = mods, key = 'p', action = act.PasteFrom 'Clipboard' },
    { mods = 'ALT', key = '1', action = act.ActivateTab(0) },
    { mods = 'ALT', key = '2', action = act.ActivateTab(1) },
    { mods = 'ALT', key = '3', action = act.ActivateTab(2) },
    { mods = 'ALT', key = '4', action = act.ActivateTab(3) },
    { mods = 'ALT', key = '5', action = act.ActivateTab(4) },
}

wezterm.on('format-tab-title', function(tab)
    -- Get the process name.
    local process = string.gsub(tab.active_pane.foreground_process_name, '(.*[/\\])(.*)', '%2')

    -- Current working directory.
    local cwd = tab.active_pane.current_working_dir
    cwd = cwd and string.format('%s ', cwd.file_path:gsub(os.getenv 'HOME', '~')) or ''

    -- Format and return the title.
    return string.format('(%d %s) %s', tab.tab_index + 1, process, cwd)
end)

return config
