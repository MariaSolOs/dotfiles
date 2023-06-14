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

                local nmap = function(l, r, desc)
                    vim.keymap.set('n', l, r, { buffer = bufnr, desc = desc })
                end

                nmap(']c', function()
                    if vim.wo.diff then return ']c' end
                    vim.schedule(function() gs.next_hunk() end)
                    return '<Ignore>'
                end, 'Go to next hunk')
                nmap('[c', function()
                    if vim.wo.diff then return '[c' end
                    vim.schedule(function() gs.prev_hunk() end)
                    return '<Ignore>'
                end, 'Go to previous hunk')
                nmap('<leader>hs', gs.stage_hunk, 'Stage hunk')
                nmap('<leader>hr', gs.reset_hunk, 'Reset hunk')
                nmap('<leader>hS', gs.stage_buffer, 'Stage all hunks in buffer')
                nmap('<leader>hu', gs.undo_stage_hunk, 'Undo stage hunk')
                nmap('<leader>hR', gs.reset_buffer, 'Reset hunks in buffer')
                nmap('<leader>hp', gs.preview_hunk, 'Preview hunk')
                nmap('<leader>hb', gs.blame_line, 'Blame line')
                nmap('<leader>hd', gs.diffthis, 'Diff against the index')
                nmap('<leader>hD', function() gs.diffthis('~') end, 'Diff against the last commit')
                nmap('<leader>hq', function() gs.setqflist('all') end, 'TroubleToggle quickfix list with hunks')
            end
        },
    }
}
