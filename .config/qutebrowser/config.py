from qutebrowser.config.configfiles import ConfigAPI
from qutebrowser.config.config import ConfigContainer

config: ConfigAPI = config # pyright: ignore[reportUndefinedVariable]
c: ConfigContainer = c # pyright: ignore[reportUndefinedVariable]

palette = {
    'background': '#0E1419',
    'background-attention': '#000000',
    'selection': '#3C4148',
    'foreground': '#F6F6F5',
    'foreground-attention': '#FFFFFF',
    'comment': '#B08BBB',
    'cyan': '#A7DFEF',
    'green': '#87E58E',
    'orange': '#FFBFA9',
    'pink': '#E48CC1',
    'purple': '#D0B5F3',
    'red': '#E95678',
    'fuchsia': '#E11299'
}

# Background color of the completion widget category headers.
c.colors.completion.category.bg = palette['background-attention']

# Border color of the completion widget category headers.
c.colors.completion.category.border.bottom = palette['foreground-attention']
c.colors.completion.category.border.top = palette['foreground-attention']

# Foreground color of completion widget category headers.
c.colors.completion.category.fg = palette['foreground']

# Background color of the completion widget for even rows.
c.colors.completion.even.bg = palette['background']

# Text color of the completion widget.
c.colors.completion.fg = [palette['cyan'], palette['foreground'], palette['foreground']]

# Background color of the selected completion item.
c.colors.completion.item.selected.bg = palette['selection']

# Border color for the selected completion item.
c.colors.completion.item.selected.border.bottom = palette['selection']
c.colors.completion.item.selected.border.top = palette['selection']

# Foreground color of the selected completion item.
c.colors.completion.item.selected.fg = palette['cyan']

# Foreground color of the matched text in the completion widget.
c.colors.completion.item.selected.match.fg = palette['fuchsia']
c.colors.completion.match.fg = palette['fuchsia']

# Background color of the completion widget for odd rows.
c.colors.completion.odd.bg = palette['background']

# Color of the scrollbar in completion view
c.colors.completion.scrollbar.bg = palette['background']

# Color of the scrollbar handle in completion view.
c.colors.completion.scrollbar.fg = palette['selection']

# Background color for hints.
c.colors.hints.bg = palette['pink']

# Font color for hints.
c.colors.hints.fg = palette['background-attention']

# Font color for the matched part of hints.
c.colors.hints.match.fg = palette['fuchsia']

# Background color of an error message.
c.colors.messages.error.bg = palette['red']

# Font color of an error message.
c.colors.messages.error.fg = palette['foreground']

# Background color of the statusbar in insert mode.
c.colors.statusbar.insert.bg = palette['green']

# Foreground color of the statusbar in insert mode.
c.colors.statusbar.insert.fg = palette['background']

# Background color of the statusbar.
c.colors.statusbar.normal.bg = palette['background-attention']

# Foreground color of the statusbar.
c.colors.statusbar.normal.fg = palette['purple']

# Default foreground color of the URL in the statusbar.
c.colors.statusbar.url.fg = palette['purple']

# Foreground color of the URL in the statusbar on successful load.
c.colors.statusbar.url.success.http.fg = palette['purple']
c.colors.statusbar.url.success.https.fg = palette['purple']

# Background color of the tab bar.
c.colors.tabs.bar.bg = palette['background-attention']

# Background color of unselected even tabs.
c.colors.tabs.even.bg = palette['background-attention']

# Foreground color of unselected even tabs.
c.colors.tabs.even.fg = palette['comment']

# Background color of unselected odd tabs.
c.colors.tabs.odd.bg = palette['background-attention']

# Foreground color of unselected odd tabs.
c.colors.tabs.odd.fg = palette['comment']

# Background color of selected tabs.
c.colors.tabs.selected.even.bg = palette['background']
c.colors.tabs.selected.odd.bg = palette['background']

# CSS border value for hints.
c.hints.border = '0px'

# The default font.
c.fonts.default_family = 'Hasklug Nerd Font Mono'
c.fonts.default_size = '11px'

# Open Google when using :open with no URL.
c.url.default_page = 'https://www.google.com/'

# Configure Google as the default search engine.
c.url.searchengines = { 'DEFAULT': 'https://www.google.com/search?q={}' }

# Open Google at the start.
c.url.start_pages = 'https://www.google.com/'

# Disable the progress indicator.
c.tabs.indicator.width = 0

# Tab bar padding.
c.tabs.padding = { 'bottom': 4, 'left': 4, 'right': 4, 'top': 4 }

# Zoom level.
c.zoom.default = '90%'

with config.pattern('*://github.com/*') as pattern:
    # For using GitHub shortcuts.
    c.input.forward_unbound_keys = 'all'

# Apply the settings from the UI.
config.load_autoconfig()
