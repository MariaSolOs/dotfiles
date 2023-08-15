-- Whitespace and indentation guides.
return {
    {
        'lukas-reineke/indent-blankline.nvim',
        -- For setting shiftwidth and tabstop automatically.
        dependencies = 'tpope/vim-sleuth',
        event = { 'BufReadPost', 'BufNewFile' },
        opts = {
            show_trailing_blankline_indent = false,
            char_priority = 12,
            show_foldtext = false,
            filetype_exclude = {
                'Trouble',
                'alpha',
                'help',
                'lazy',
                'lazyterm',
                'mason',
            },
        },
    },
}
