local sign_icon = require('icons').misc.vertical_bar

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

                -- Register the leader group with miniclue.
                vim.b[bufnr].miniclue_config = {
                    clues = {
                        { mode = 'n', keys = '<leader>g', desc = '+git' },
                    },
                }

                -- Mappings.
                ---@param lhs string
                ---@param rhs function
                ---@param desc string
                ---@param mode? string
                local function map(lhs, rhs, desc, mode)
                    vim.keymap.set(mode or 'n', lhs, rhs, { desc = desc, buffer = bufnr })
                end
                map('<leader>gc', function()
                    require('gitlinker').get_buf_range_url 'v'
                end, 'Copy to clipboard', 'v')
                map('<leader>go', function()
                    require('gitlinker').get_buf_range_url(
                        'n',
                        { action_callback = require('gitlinker.actions').open_in_browser }
                    )
                end, 'Open in browser')
                map(']g', gs.prev_hunk, 'Previous hunk')
                map('[g', gs.next_hunk, 'Next hunk')
                map('<leader>gR', gs.reset_buffer, 'Reset buffer')
                map('<leader>gb', gs.blame_line, 'Blame line')
                map('<leader>gp', gs.preview_hunk, 'Preview hunk')
                map('<leader>gr', gs.reset_hunk, 'Reset hunk')
                map('<leader>gs', gs.stage_hunk, 'Stage hunk')
                map('<leader>gh', function()
                    gs.setloclist(0, 'all')
                end, 'Hunks')
                map('<leader>gl', function()
                    require('float_term').float_term('lazygit', {
                        size = { width = 0.85, height = 0.8 },
                        cwd = vim.b.gitsigns_status_dict.root,
                    })
                end, 'Lazygit')
            end,
        },
    },
}
