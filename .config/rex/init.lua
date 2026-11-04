-- Rex configuration.
-- Key bindings ported from ~/.config/ghostty/config.

-- Tabs:
for i = 1, 5 do
  rex.bind("alt+" .. i, "client.tab.goto", { index = i })
end
rex.bind("shift+alt+t", "client.tab.new")

-- Config:
rex.bind("shift+alt+,", "client.config.reload")

-- Panes:
rex.bind("shift+alt+q", "client.close")
rex.bind("shift+alt+v", "pane.split", { direction = "right" })
rex.bind("shift+alt+s", "pane.split", { direction = "down" })
rex.bind("shift+alt+k", "pane.focus", { direction = "up", wrap = false })
rex.bind("shift+alt+j", "pane.focus", { direction = "down", wrap = false })
rex.bind("shift+alt+h", "pane.focus", { direction = "left", wrap = false })
rex.bind("shift+alt+l", "pane.focus", { direction = "right", wrap = false })

-- Font size:
rex.bind("alt+=", "client.font.increase")
rex.bind("alt+-", "client.font.decrease")
rex.bind("alt+0", "client.font.reset")

-- Window:
rex.bind("shift+alt+enter", "client.window.fullscreen.toggle")
rex.bind("shift+alt+w", "client.palette.toggle")
