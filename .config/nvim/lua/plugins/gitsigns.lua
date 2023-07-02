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
                keymap('<leader>gb', gs.blame_line, 'Blame line')
                keymap('<leader>gs', gs.stage_hunk, 'Stage hunk')
                keymap('<leader>gr', gs.reset_hunk, 'Reset hunk')
                keymap('<leader>gS', gs.stage_buffer, 'Stage all hunks in buffer')
                keymap('<leader>gu', gs.undo_stage_hunk, 'Undo stage hunk')
                keymap('<leader>gR', gs.reset_buffer, 'Reset hunks in buffer')
                keymap('<leader>gp', gs.preview_hunk, 'Preview hunk')
                keymap('<leader>xh', function()
                    gs.setqflist 'all'
                end, 'Hunks')

                -- Add group prefix for which-key.
                require('which-key').register {
                    ['<leader>g'] = { name = '+git' },
                }
            end,
        },
    },
}
