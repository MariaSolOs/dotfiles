-- Adds git releated signs to the gutter, as well as utilities for managing changes.
return {
    {
        'lewis6991/gitsigns.nvim',
        event = { 'BufReadPre', 'BufNewFile' },
        opts = {
            signs = {
                add = { text = '+' },
                untracked = { text = '+' },
                change = { text = '~' },
                delete = { text = '_' },
                topdelete = { text = '‾' },
                changedelete = { text = '~' },
            },
            on_attach = function(bufnr)
                vim.keymap.set('n', '[c', require('gitsigns').prev_hunk,
                    { buffer = bufnr, desc = 'Go to Previous Hunk' })
                vim.keymap.set('n', ']c', require('gitsigns').next_hunk,
                    { buffer = bufnr, desc = 'Go to Next Hunk' })
                vim.keymap.set('n', '<leader>ph', require('gitsigns').preview_hunk,
                    { buffer = bufnr, desc = '[P]review [H]unk' })
                vim.keymap.set('n', '<leader>sth', require('gitsigns').stage_hunk,
                    { buffer = bufnr, desc = '[St]age [H]unk' })
                vim.keymap.set('n', '<leader>df~', function() require('gitsigns').diffthis('~') end,
                    { buffer = bufnr, desc = '[D]i[f]f with [~]' })
            end,
        },
    }
}
