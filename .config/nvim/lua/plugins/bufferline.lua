local diagnostic_icons = require('icons').diagnostics

-- Bufferline for pretty tabs.
return {
    {
        'akinsho/bufferline.nvim',
        event = { 'BufReadPre', 'BufNewFile' },
        opts = {
            options = {
                close_command = function(bufnr)
                    require('mini.bufremove').delete(bufnr, false)
                end,
                right_mouse_command = function(bufnr)
                    require('mini.bufremove').delete(bufnr, false)
                end,
                diagnostics = 'nvim_lsp',
                diagnostics_indicator = function(_, _, diag)
                    local indicator = (diag.error and diagnostic_icons.ERROR .. ' ' or '')
                        .. (diag.warning and diagnostic_icons.WARN or '')
                    return vim.trim(indicator)
                end,
                diagnostics_update_in_insert = false,
            },
        },
        keys = {
            -- Buffer navigation.
            { '[b', '<cmd>BufferLineCyclePrev<cr>', desc = 'Previous buffer' },
            { ']b', '<cmd>BufferLineCycleNext<cr>', desc = 'Next buffer' },
            { '<leader>bc', '<cmd>BufferLinePickClose<cr>', desc = 'Select a buffer to close' },
            { '<leader>bl', '<cmd>BufferLineCloseLeft<cr>', desc = 'Close buffers to the left' },
            { '<leader>bo', '<cmd>BufferLinePick<cr>', desc = 'Select a buffer to open' },
            { '<leader>br', '<cmd>BufferLineCloseRight<cr>', desc = 'Close buffers to the right' },
            -- Tab navigation.
            { '<leader>tc', '<cmd>tabclose<cr>', desc = 'Close tab page' },
            { '<leader>tn', '<cmd>tab split<cr>', desc = 'New tab page' },
            { '<leader>to', '<cmd>tabonly<cr>', desc = 'Close other tab pages' },
        },
    },
}
