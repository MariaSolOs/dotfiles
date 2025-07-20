local solid_bar = require('icons').misc.vertical_bar
local dashed_bar = require('icons').misc.dashed_bar

-- Adds git releated signs to the gutter, as well as utilities for managing changes.
return {
    {
        'lewis6991/gitsigns.nvim',
        event = { 'BufReadPre', 'BufNewFile' },
        opts = {
            signs = {
                add = { text = solid_bar },
                untracked = { text = solid_bar },
                change = { text = solid_bar },
                delete = { text = solid_bar },
                topdelete = { text = solid_bar },
                changedelete = { text = solid_bar },
            },
            signs_staged = {
                add = { text = dashed_bar },
                untracked = { text = dashed_bar },
                change = { text = dashed_bar },
                delete = { text = dashed_bar },
                topdelete = { text = dashed_bar },
                changedelete = { text = dashed_bar },
            },
            preview_config = { border = 'rounded' },
            current_line_blame = true,
            gh = true,
            on_attach = function(bufnr)
                local gitlinker = require 'gitlinker'
                local gs = package.loaded.gitsigns

                -- Register the leader group with miniclue.
                vim.b[bufnr].miniclue_config = {
                    clues = {
                        { mode = 'n', keys = '<leader>g', desc = '+git' },
                        { mode = 'x', keys = '<leader>g', desc = '+git' },
                    },
                }

                -- Gitlinker doesn't add descriptions.
                local miniclue = require 'mini.clue'
                miniclue.set_mapping_desc('n', '<leader>gc', 'Copy GitHub link')
                miniclue.set_mapping_desc('v', '<leader>gc', 'Copy GitHub link')

                -- Mappings.
                ---@param lhs string
                ---@param rhs function
                ---@param desc string
                local function nmap(lhs, rhs, desc)
                    vim.keymap.set('n', lhs, rhs, { desc = desc, buffer = bufnr })
                end
                nmap('<leader>go', function()
                    gitlinker.get_buf_range_url('n', { action_callback = require('gitlinker.actions').open_in_browser })
                end, 'Open in browser')
                nmap('[g', gs.prev_hunk, 'Previous hunk')
                nmap(']g', gs.next_hunk, 'Next hunk')
                nmap('<leader>gR', gs.reset_buffer, 'Reset buffer')
                nmap('<leader>gb', gs.blame_line, 'Blame line')
                nmap('<leader>gp', gs.preview_hunk, 'Preview hunk')
                nmap('<leader>gr', gs.reset_hunk, 'Reset hunk')
                nmap('<leader>gs', gs.stage_hunk, 'Stage hunk')
                nmap('<leader>gl', function()
                    require('float_term').float_term('lazygit', {
                        size = { width = 0.85, height = 0.8 },
                        cwd = vim.b.gitsigns_status_dict.root,
                    })
                end, 'Lazygit')
            end,
        },
    },
}
