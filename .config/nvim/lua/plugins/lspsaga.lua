-- Nicer UI.
return {
    {
        'glepnir/lspsaga.nvim',
        cmd = 'Lspsaga',
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
            rename = {
                quit = '<esc>',
            },
            -- Using barbecue instead.
            symbol_in_winbar = {
                enable = false,
            },
        },
    },
}
