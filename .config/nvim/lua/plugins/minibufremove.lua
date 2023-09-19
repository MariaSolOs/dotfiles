-- Save the window layout when closing a buffer.
return {
    {
        'echasnovski/mini.bufremove',
        config = true,
        keys = {
            {
                '<leader>bd',
                function()
                    require('mini.bufremove').delete(0, false)
                end,
                desc = 'Delete current buffer',
            },
            {
                '<leader>bD',
                function()
                    require('mini.bufremove').delete(0, true)
                end,
                desc = 'Delete (!) current buffer',
            },
        },
    },
}
