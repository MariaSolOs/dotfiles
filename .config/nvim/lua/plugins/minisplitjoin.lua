-- Split/join blocks of code.
return {
    {
        'echasnovski/mini.splitjoin',
        keys = {
            {
                '<leader>cj',
                function()
                    require('mini.splitjoin').toggle()
                end,
                desc = 'Join/split code block',
            },
        },
        opts = {
            mappings = {
                toggle = '<leader>cj',
            },
        },
    },
}
