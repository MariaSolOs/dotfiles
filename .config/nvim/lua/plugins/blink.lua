-- Auto-completion:
-- TODO: Add commands for scrolling the documentation window.
return {
    {
        'saghen/blink.cmp',
        build = 'cargo +nightly build --release',
        event = 'InsertEnter',
        opts = {
            keymap = {
                ['<CR>'] = { 'accept', 'fallback' },
                ['/'] = { 'hide', 'fallback' },
                ['<C-n>'] = { 'select_next', 'show' },
                ['<Tab>'] = { 'select_next', 'fallback' },
                ['<C-p>'] = { 'select_prev' },
            },
            completion = {
                list = {
                    -- Insert items while navigating the completion list.
                    selection = 'auto_insert',
                    max_items = 10,
                },
                menu = {
                    border = 'rounded',
                },
                documentation = {
                    auto_show = true,
                    window = { border = 'rounded' },
                },
            },
            sources = {
                -- Disable command line completion:
                cmdline = {},
            },
            appearance = {
                kind_icons = require('icons').symbol_kinds,
            },
        },
    },
}
