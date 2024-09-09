-- Git integration.
return {
    {
        'echasnovski/mini-git',
        main = 'mini.git',
        opts = {},
        lazy = false,
        keys = {
            {
                '<leader>gd',
                function()
                    require('mini.git').show_at_cursor {}
                end,
                desc = 'Show info at cursor',
                mode = { 'n', 'x' },
            },
        },
    },
}
