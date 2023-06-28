-- Nicer UI.
return {
    {
        'glepnir/lspsaga.nvim',
        cmd = 'Lspsaga',
        dependencies = {
            'nvim-tree/nvim-web-devicons',
            'nvim-treesitter/nvim-treesitter',
        },
        opts = {
            ui = {
                border = 'rounded',
                code_action = '',
            },
            outline = {
                keys = {
                    expand_or_jump = '<cr>',
                },
                auto_resize = true,
            },
            finder = {
                keys = {
                    jump_to = '<Tab>',
                    expand_or_jump = '<cr>',
                },
            },
        },
    },
}
