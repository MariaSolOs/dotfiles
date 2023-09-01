local gutter_icon = '│'

-- Adds git releated signs to the gutter, as well as utilities for managing changes.
return {
    {
        'lewis6991/gitsigns.nvim',
        event = { 'BufReadPre', 'BufNewFile' },
        opts = {
            signs = {
                add = { text = gutter_icon },
                untracked = { text = gutter_icon },
                change = { text = gutter_icon },
                delete = { text = gutter_icon },
                topdelete = { text = gutter_icon },
                changedelete = { text = gutter_icon },
            },
            preview_config = { border = 'rounded' },
            on_attach = function(bufnr)
                local gs = package.loaded.gitsigns

                -- At this point I know that I'm in a git repo, so load git-conflict too.
                require('lazy').load { plugins = { 'git-conflict.nvim' } }

                local function keymap(lhs, rhs, desc, opts)
                    opts = opts or {}
                    opts.desc = desc
                    opts.buffer = bufnr
                    vim.keymap.set('n', lhs, rhs, opts)
                end

                keymap(']g', gs.next_hunk, 'Next hunk')
                keymap('[g', gs.prev_hunk, 'Previous hunk')

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
