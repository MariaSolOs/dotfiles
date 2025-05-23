-- Copilot completion.
return {
    {
        'zbirenbaum/copilot.lua',
        event = 'InsertEnter',
        opts = {
            -- The panel is useless.
            panel = { enabled = false },
            suggestion = {
                hide_during_completion = false,
                keymap = {
                    accept = '<C-.>',
                    accept_word = '<M-w>',
                    accept_line = '<M-l>',
                    next = '<M-]>',
                    prev = '<M-[>',
                    dismiss = '<C-/>',
                },
            },
            filetypes = {
                markdown = true,
            },
        },
    },
}
