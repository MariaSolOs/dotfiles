-- Whitespace and indentation guides.
return {
    {
        'lukas-reineke/indent-blankline.nvim',
        event = { 'BufReadPost', 'BufNewFile' },
        opts = {
            show_trailing_blankline_indent = false,
            char_priority = 12,
            show_foldtext = false,
        },
    },
}
