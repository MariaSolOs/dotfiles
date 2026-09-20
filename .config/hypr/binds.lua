-- Window bindings:
hl.bind('SUPER + A', hl.dsp.window.fullscreen { mode = 'fullscreen', action = 'toggle' })
hl.bind('SUPER + M', hl.dsp.window.center())
hl.bind('SUPER + F', hl.dsp.window.float { action = 'toggle' })

-- DIE!
hl.bind('SUPER + Q', hl.dsp.exec_cmd '$XDG_CONFIG_HOME/hypr/scripts/conditional-kill.sh')
hl.bind('SUPER + SHIFT + Q', hl.dsp.exec_cmd '$XDG_CONFIG_HOME/hypr/scripts/exit-hypr.sh')

-- Applications:
hl.bind('XF86Search', hl.dsp.exec_cmd 'rofi -show combi')
hl.bind('SUPER + B', hl.dsp.exec_cmd 'chromium')
hl.bind('SUPER + T', hl.dsp.exec_cmd 'ghostty')
hl.bind('SUPER + C', hl.dsp.focus { workspace = 'name:comms' })
hl.bind('SUPER + O', hl.dsp.focus { workspace = 'name:obsidian' })

-- Notifications:
hl.bind('SUPER + N', hl.dsp.exec_cmd 'swaync-client -t')

-- Screenshots:
hl.bind('SUPER + SHIFT + S', hl.dsp.exec_cmd '$XDG_CONFIG_HOME/hypr/scripts/screenshot.sh')

-- Paste from clipboard history:
hl.bind(
    'SHIFT + CTRL + V',
    hl.dsp.exec_cmd 'cliphist list | rofi -dmenu | cliphist decode | wl-copy && wtype -M ctrl -k v -m ctrl'
)

-- Audio:
hl.bind('XF86AudioLowerVolume', hl.dsp.exec_cmd '$XDG_CONFIG_HOME/hypr/scripts/volume.sh --dec', { repeating = true })
hl.bind('XF86AudioRaiseVolume', hl.dsp.exec_cmd '$XDG_CONFIG_HOME/hypr/scripts/volume.sh --inc', { repeating = true })
hl.bind('XF86AudioMute', hl.dsp.exec_cmd '$XDG_CONFIG_HOME/hypr/scripts/volume.sh --toggle-mut')

-- Screen backlight:
hl.bind(
    'XF86MonBrightnessDown',
    hl.dsp.exec_cmd '$XDG_CONFIG_HOME/hypr/scripts/backlight.sh --dec',
    { repeating = true }
)
hl.bind('XF86MonBrightnessUp', hl.dsp.exec_cmd '$XDG_CONFIG_HOME/hypr/scripts/backlight.sh --inc', { repeating = true })

-- Focus with SUPER + HJKL:
hl.bind('SUPER + h', hl.dsp.focus { direction = 'left' })
hl.bind('SUPER + l', hl.dsp.focus { direction = 'right' })
hl.bind('SUPER + k', hl.dsp.focus { direction = 'up' })
hl.bind('SUPER + j', hl.dsp.focus { direction = 'down' })

-- Switch workspaces / move windows with SUPER [+ SHIFT] + [1-5]:
for i = 1, 5 do
    hl.bind('SUPER + ' .. i, hl.dsp.focus { workspace = i })
    hl.bind('SUPER + SHIFT + ' .. i, hl.dsp.window.move { workspace = i, follow = true })
end
