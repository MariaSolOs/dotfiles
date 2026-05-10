local add = require('vim-pack').add

-- Find and replace.
add {
    {
        src = 'MagicDuck/grug-far.nvim',
        opts = {
            -- Disable folding.
            folding = { enabled = false },
            -- Don't numerate the result list.
            resultLocation = { showNumberLabel = false },
        },
        on_setup = function()
            vim.keymap.set({ 'n', 'v' }, '<leader>cg', function()
                require('grug-far').open { transient = true }
            end, { desc = 'GrugFar' })
        end,
    },
}
