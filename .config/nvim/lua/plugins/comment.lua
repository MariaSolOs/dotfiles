-- 'gc' to comment visual regions/lines.
return {
    {
        'numToStr/Comment.nvim',
        opts = {
            extra = { above = 'gch', below = 'gcl' },
        },
        event = 'VeryLazy',
    },
}
