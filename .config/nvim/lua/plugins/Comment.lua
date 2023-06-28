-- 'gc' to comment visual regions/lines.
return {
    {
        'numToStr/Comment.nvim',
        event = 'VeryLazy',
        opts = {
            extra = { above = 'gch', below = 'gcl' },
        },
    },
}
