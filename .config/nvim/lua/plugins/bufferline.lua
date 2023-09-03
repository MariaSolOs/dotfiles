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
        keys = {
            -- Buffer navigation.
            { '[b', '<cmd>BufferLineCyclePrev<cr>', desc = 'Previous buffer' },
            { ']b', '<cmd>BufferLineCycleNext<cr>', desc = 'Next buffer' },
            { '<leader>bc', '<cmd>BufferLinePickClose<cr>', desc = 'Select a buffer to close' },
            { '<leader>bd', '<cmd>bdelete<cr>', desc = 'Delete current buffer' },
            { '<leader>bl', '<cmd>BufferLineCloseLeft<cr>', desc = 'Close buffers to the left' },
            { '<leader>bo', '<cmd>BufferLinePick<cr>', desc = 'Select a buffer to open' },
            { '<leader>br', '<cmd>BufferLineCloseRight<cr>', desc = 'Close buffers to the right' },
            -- Tab navigation.
            { '[p', '<cmd>tabp<cr>', desc = 'Previous tab page' },
            { ']p', '<cmd>tabn<cr>', desc = 'Next tab page' },
            { '<leader>pc', '<cmd>tabclose<cr>', desc = 'Close tab page' },
            { '<leader>pn', '<cmd>tab split<cr>', desc = 'New tab page' },
            { '<leader>po', '<cmd>tabonly<cr>', desc = 'Close other tab pages' },
        },
    },
}
