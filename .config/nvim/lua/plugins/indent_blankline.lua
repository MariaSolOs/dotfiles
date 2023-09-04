-- Whitespace and indentation guides.
return {
    {
        'lukas-reineke/indent-blankline.nvim',
        event = 'VeryLazy',
        -- For setting shiftwidth and tabstop automatically.
        dependencies = 'tpope/vim-sleuth',
        opts = {
            show_trailing_blankline_indent = false,
            char_priority = 12,
            show_foldtext = false,
            filetype_exclude = {
                'alpha',
                'help',
                'lazy',
                'lazyterm',
                'mason',
                'noice',
                'qf',
            },
        },
    },
}
