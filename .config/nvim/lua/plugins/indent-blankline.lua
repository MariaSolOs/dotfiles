return {
    {
        -- Whitespace and indentation guides.
        'lukas-reineke/indent-blankline.nvim',
        event = { 'BufReadPost', 'BufNewFile' },
        opts = {
            show_trailing_blankline_indent = false,
            char_priority = 12,
        },
    },
}
