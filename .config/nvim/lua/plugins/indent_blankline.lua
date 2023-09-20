-- Whitespace and indentation guides.
return {
    {
        'lukas-reineke/indent-blankline.nvim',
        main = 'ibl',
        -- TODO: Remove this when the PR gets merged to master.
        branch = 'v3',
        event = 'VeryLazy',
        -- For setting shiftwidth and tabstop automatically.
        dependencies = 'tpope/vim-sleuth',
        opts = {
            scope = { enabled = false },
            indent = {
                char = require('icons').misc.vertical_bar,
                -- Make sure the guides are visible in folded lines (ufo
                -- uses a priority of 10).
                priority = 11,
            },
            exclude = {
                filetypes = {
                    'alpha',
                    'lazy',
                    'lazyterm',
                    'mason',
                },
            },
        },
    },
}
