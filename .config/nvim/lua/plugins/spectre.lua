-- Search and replace in multiple files.
return {
    {
        'nvim-pack/nvim-spectre',
        dependencies = 'nvim-lua/plenary.nvim',
        opts = { open_cmd = 'noswapfile vnew' },
        keys = {
            {
                '<leader>cS',
                function()
                    require('spectre').open()
                end,
                desc = 'Search and replace',
            },
        },
    },
}
