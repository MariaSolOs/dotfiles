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
                local gs = package.loaded.gitsigns

                local keymap = function(lhs, rhs, desc, opts)
                    opts = opts or {}
                    opts.desc = desc
                    opts.buffer = bufnr
                    vim.keymap.set('n', lhs, rhs, opts)
                end

                keymap(']g', function()
                    if vim.wo.diff then
                        return ']g'
                    end
                    vim.schedule(function()
                        gs.next_hunk()
                    end)
                    return '<Ignore>'
                end, 'Next hunk', { expr = true })
                keymap('[g', function()
                    if vim.wo.diff then
                        return '[g'
                    end
                    vim.schedule(function()
                        gs.prev_hunk()
                    end)
                    return '<Ignore>'
                end, 'Previous hunk', { expr = true })
                keymap('<leader>xh', function()
                    gs.setqflist 'all'
                end, 'Hunks')

                require('which-key').register {
                    ['<leader>g'] = {
                        name = '+git',
                        b = { gs.blame_line, 'Blame line', buffer = bufnr },
                        p = { gs.preview_hunk, 'Preview hunk', buffer = bufnr },
                        r = { gs.reset_hunk, 'Reset hunk', buffer = bufnr },
                        R = { gs.reset_buffer, 'Reset buffer', buffer = bufnr },
                        s = { gs.stage_hunk, 'Stage hunk', buffer = bufnr },
                        S = { gs.stage_buffer, 'Stage buffer', buffer = bufnr },
                        u = { gs.undo_stage_hunk, 'Undo stage hunk', buffer = bufnr },
                    },
                }
            end,
        },
    },
}
