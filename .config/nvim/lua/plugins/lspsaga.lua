-- Nice LSP UI.
return {
    {
        'nvimdev/lspsaga.nvim',
        event = 'LspAttach',
        opts = {
            lightbulb = {
                sign = false,
                enable_in_insert = false,
            },
            code_action = {
                keys = {
                    quit = { '<esc>', 'q' },
                },
            },
            outline = {
                win_width = 50,
                keys = {
                    toggle_or_jump = '<cr>',
                },
            },
            rename = {
                keys = {
                    quit = '<esc>',
                },
            },
            ui = {
                code_action = ' ' .. require('helpers.icons').diagnostics.Hint,
                border = 'rounded',
            },
        },
    },
}
