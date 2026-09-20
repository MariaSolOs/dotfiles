-- GTK3 editor:
hl.window_rule {
    match = { class = 'nwg-look' },
    float = true,
    size = { 800, 500 },
}

-- Bitwarden vault login:
hl.window_rule {
    match = { class = '(chrome-)(.*)', initial_title = '(_crx_)(.*)' },
    center = true,
    float = true,
    size = { 500, 600 },
}

-- Pinentry:
hl.window_rule {
    match = { class = 'pinentry-gtk' },
    center = true,
    float = true,
    size = { 400, 140 },
}

-- File dialogs:
hl.window_rule {
    match = { class = 'xdg-desktop-portal-gtk' },
    center = true,
    float = true,
    size = { 900, 600 },
}
hl.window_rule {
    match = { class = 'chromium', title = '(Open|Save) Files' },
    center = true,
    float = true,
    size = { 900, 550 },
}

-- New mail window:
hl.window_rule {
    match = { class = '(.*)Thunderbird', title = '^Write(.*)' },
    float = true,
    size = { 800, 600 },
}

-- PWAs:
hl.window_rule {
    match = { class = '(chrome-)(.*)', initial_title = 'Element' },
    center = true,
    float = true,
    size = { 1100, 780 },
}
