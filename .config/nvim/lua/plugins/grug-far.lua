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
            -- TODO: Pick up my fix from https://github.com/MagicDuck/grug-far.nvim/pull/510.
            folding = { enabled = false },
            -- Don't numerate the result list.
            resultLocation = { showNumberLabel = false },
        },
    },
}
