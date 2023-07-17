return {
    {
        'nvimdev/lspsaga.nvim',
        event = 'LspAttach',
        opts = {
            lightbulb = {
                sign = false,
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
                code_action = ' ',
                border = 'rounded',
            },
        },
    },
}
