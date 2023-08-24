-- 'gc' to comment visual regions/lines.
return {
    {
        'numToStr/Comment.nvim',
        config = true,
        keys = {
            { 'gcc', desc = 'Toggle line comment' },
            { 'gc', mode = { 'n', 'x', 'o' }, desc = 'Toggle comment' },
        },
    },
}
