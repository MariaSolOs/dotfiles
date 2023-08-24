-- 'gc' to comment visual regions/lines.
return {
    {
        'numToStr/Comment.nvim',
        config = true,
        keys = {
            'gcc',
            { 'gc', mode = { 'n', 'x', 'o' } },
        },
    },
}
