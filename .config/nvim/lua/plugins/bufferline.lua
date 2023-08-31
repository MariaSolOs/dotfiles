local diagnostic_icons = require('icons').diagnostics

-- Bufferline for pretty tabs.
return {
    {
        'akinsho/bufferline.nvim',
        event = { 'BufReadPre', 'BufNewFile' },
        opts = {
            options = {
                diagnostics = 'nvim_lsp',
                diagnostics_indicator = function(_, _, diag)
                    local indicator = (diag.error and diagnostic_icons.ERROR .. ' ' or '')
                        .. (diag.warning and diagnostic_icons.WARN or '')
                    return vim.trim(indicator)
                end,
                diagnostics_update_in_insert = false,
            },
        },
        config = function(_, opts)
            require('bufferline').setup(opts)

            -- Buffer and tab navigation.
            vim.keymap.set('n', '[b', '<cmd>BufferLineCyclePrev<cr>', { desc = 'Previous buffer' })
            vim.keymap.set('n', ']b', '<cmd>BufferLineCycleNext<cr>', { desc = 'Next buffer' })
            vim.keymap.set('n', '[p', '<cmd>tabp<cr>', { desc = 'Previous tab page' })
            vim.keymap.set('n', ']p', '<cmd>tabn<cr>', { desc = 'Next tab page' })
            require('which-key').register {
                ['<leader>b'] = {
                    name = '+buffers',
                    c = { '<cmd>BufferLinePickClose<cr>', 'Select a buffer to close' },
                    d = { '<cmd>bdelete<cr>', 'Delete current buffer' },
                    l = { '<cmd>BufferLineCloseLeft<cr>', 'Close buffers to the left' },
                    o = { '<cmd>BufferLinePick<cr>', 'Select a buffer to open' },
                    r = { '<cmd>BufferLineCloseRight<cr>', 'Close buffers to the right' },
                },
                ['<leader>p'] = {
                    name = '+tabs',
                    c = { '<cmd>tabclose<cr>', 'Close tab page' },
                    n = { '<cmd>tab split<cr>', 'New tab page' },
                    o = { '<cmd>tabonly<cr>', 'Close other tab pages' },
                },
            }
        end,
    },
}
