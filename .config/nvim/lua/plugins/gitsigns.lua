local sign_icon = '│'

-- Adds git releated signs to the gutter, as well as utilities for managing changes.
return {
    {
        'lewis6991/gitsigns.nvim',
        event = { 'BufReadPre', 'BufNewFile' },
        opts = {
            signs = {
                add = { text = sign_icon },
                untracked = { text = sign_icon },
                change = { text = sign_icon },
                delete = { text = sign_icon },
                topdelete = { text = sign_icon },
                changedelete = { text = sign_icon },
            },
            preview_config = { border = 'rounded' },
            on_attach = function(bufnr)
                local gs = package.loaded.gitsigns

                -- At this point I know that I'm in a git repo, so load git-conflict too.
                require('lazy').load { plugins = { 'git-conflict.nvim' } }

                vim.keymap.set('n', ']g', gs.next_hunk, { desc = 'Next hunk', buffer = bufnr })
                vim.keymap.set('n', '[g', gs.prev_hunk, { desc = 'Previous hunk', buffer = bufnr })

                require('which-key').register {
                    ['<leader>g'] = {
                        name = '+git',
                        b = { gs.blame_line, 'Blame line', buffer = bufnr },
                        h = {
                            function()
                                gs.setloclist(0, 'all')
                            end,
                            'Hunks',
                            buffer = bufnr,
                        },
                        l = {
                            function()
                                require('float_term').float_term('lazygit', { width = 0.8, height = 0.8 })
                            end,
                            'Lazygit',
                            buffer = bufnr,
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
