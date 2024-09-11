-- Find and replace.
return {
    {
        'MagicDuck/grug-far.nvim',
        opts = {},
        cmd = 'GrugFar',
        keys = {
            {
                '<leader>cr',
                function()
                    local grug = require 'grug-far'
                    grug.open {
                        transient = true,
                        keymaps = { help = '?' },
                    }
                end,
                desc = 'Search and replace',
                mode = { 'n', 'v' },
            },
        },
    },
}
