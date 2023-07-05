-- Nicer UI.
return {
    {
        'glepnir/lspsaga.nvim',
        event = 'LspAttach',
        dependencies = {
            'nvim-tree/nvim-web-devicons',
            'nvim-treesitter',
        },
        opts = {
            ui = {
                border = 'rounded',
                code_action = '',
            },
            outline = {
                win_width = 50,
                keys = {
                    expand_or_jump = '<cr>',
                },
            },
            finder = {
                keys = {
                    jump_to = '<Tab>',
                    expand_or_jump = '<cr>',
                },
            },
            lightbulb = {
                sign = false,
            },
            -- Using barbecue instead.
            symbol_in_winbar = {
                enable = false,
            },
        },
    },
}
