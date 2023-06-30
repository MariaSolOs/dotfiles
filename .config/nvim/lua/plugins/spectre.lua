-- Search/replace in multiple files.
return {
    {
        'nvim-pack/nvim-spectre',
        cmd = 'Spectre',
        keys = {
            {
                '<leader>S',
                function()
                    require('spectre').open()
                end,
                desc = 'Replace in files (Spectre)',
            },
        },
        config = true,
    },
}
