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

                local nmap = function(l, r, desc, opts)
                    opts = opts or {}
                    opts.desc = desc
                    opts.buffer = bufnr
                    vim.keymap.set('n', l, r, opts)
                end

                nmap(']g', function()
                    if vim.wo.diff then return ']g' end
                    vim.schedule(function() gs.next_hunk() end)
                    return '<Ignore>'
                end, 'Next hunk', { expr = true })
                nmap('[g', function()
                    if vim.wo.diff then return '[g' end
                    vim.schedule(function() gs.prev_hunk() end)
                    return '<Ignore>'
                end, 'Previous hunk', { expr = true })
                nmap('<leader>gs', gs.stage_hunk, 'Stage hunk')
                nmap('<leader>gr', gs.reset_hunk, 'Reset hunk')
                nmap('<leader>gS', gs.stage_buffer, 'Stage all hunks in buffer')
                nmap('<leader>gu', gs.undo_stage_hunk, 'Undo stage hunk')
                nmap('<leader>gR', gs.reset_buffer, 'Reset hunks in buffer')
                nmap('<leader>gp', gs.preview_hunk, 'Preview hunk')
                nmap('<leader>gb', gs.blame_line, 'Blame line')
                nmap('<leader>gd', gs.diffthis, 'Diff against the index')
                nmap('<leader>gD', function() gs.diffthis('~') end, 'Diff against the last commit')
                nmap('<leader>th', function() gs.setqflist('all') end, 'Toggle hunks')
            end
        },
    }
}
