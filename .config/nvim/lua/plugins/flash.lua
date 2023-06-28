-- Navigation with jump motions.
return {
    {
        'folke/flash.nvim',
        event = 'VeryLazy',
        opts = {
            modes = {
                -- Disable ft motions.
                char = {
                    enabled = false,
                },
            },
        },
        keys = {
            {
                's',
                mode = { 'n', 'x', 'o' },
                function()
                    require('flash').jump()
                end,
            },
        },
    },
}
