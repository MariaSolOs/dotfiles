-- Find and replace.
return {
    {
        'MagicDuck/grug-far.nvim',
        opts = {},
        cmd = 'GrugFar',
        keys = {
            {
                '<leader>cg',
                function()
                    local grug = require 'grug-far'
                    grug.open {
                        transient = true,
                        keymaps = { help = '?' },
                    }
                end,
                desc = 'GrugFar',
                mode = { 'n', 'v' },
            },
        },
    },
}
