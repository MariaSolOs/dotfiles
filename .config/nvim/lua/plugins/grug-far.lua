-- Find and replace.
return {
    {
        'MagicDuck/grug-far.nvim',
        cmd = 'GrugFar',
        keys = {
            {
                '<leader>cg',
                function()
                    local grug = require 'grug-far'
                    grug.open { transient = true }
                end,
                desc = 'GrugFar',
                mode = { 'n', 'v' },
            },
        },
        opts = {
            -- Disable folding.
            folding = { enabled = false },
            -- Don't numerate the result list.
            resultLocation = { showNumberLabel = false },
        },
    },
}
