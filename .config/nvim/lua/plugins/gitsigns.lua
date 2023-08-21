-- Adds git releated signs to the gutter, as well as utilities for managing changes.
return {
    {
        'lewis6991/gitsigns.nvim',
        event = { 'BufReadPre', 'BufNewFile' },
        opts = {
            signs = {
                add = { text = '│' },
                untracked = { text = '│' },
                change = { text = '│' },
                delete = { text = '│' },
                topdelete = { text = '│' },
                changedelete = { text = '│' },
            },
            preview_config = { border = 'rounded' },
            on_attach = function(bufnr)
                local gs = package.loaded.gitsigns

                local function keymap(lhs, rhs, desc, opts)
                    opts = opts or {}
                    opts.desc = desc
                    opts.buffer = bufnr
                    vim.keymap.set('n', lhs, rhs, opts)
                end

                keymap(']g', gs.next_hunk, 'Next hunk')
                keymap('[g', gs.prev_hunk, 'Previous hunk')
                keymap('<leader>xh', function()
                    gs.setqflist 'all'
                end, 'Hunks')

                require('which-key').register {
                    ['<leader>g'] = {
                        name = '+git',
                        b = { gs.blame_line, 'Blame line', buffer = bufnr },
                        l = {
                            function()
                                require('float_term').float_term('lazygit', { width = 0.9, height = 0.9 })
                            end,
                            'Lazygit',
                        },
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
