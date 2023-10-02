-- Whitespace and indentation guides.
return {
    {
        'lukas-reineke/indent-blankline.nvim',
        main = 'ibl',
        event = 'VeryLazy',
        -- For setting shiftwidth and tabstop automatically.
        dependencies = 'tpope/vim-sleuth',
        opts = {
            indent = {
                char = require('icons').misc.vertical_bar,
            },
            scope = {
                show_start = false,
                show_end = false,
            },
            exclude = {
                filetypes = { 'OverseerForm' },
            },
        },
    },
}
