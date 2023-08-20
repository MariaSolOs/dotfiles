-- Navigation with jump motions.
return {
    {
        'folke/flash.nvim',
        event = { 'BufReadPre', 'BufNewFile' },
        opts = {
            jump = { nohlsearch = true },
        },
        keys = {
            {
                's',
                mode = { 'n', 'x', 'o' },
                function()
                    require('flash').jump()
                end,
                desc = 'Flash',
            },
            {
                'r',
                mode = 'o',
                function()
                    require('flash').treesitter_search()
                end,
                desc = 'Treesitter Search',
            },
        },
    },
}
