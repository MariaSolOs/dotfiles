-- Pretty bufferline.
return {
    {
        'akinsho/bufferline.nvim',
        event = 'VeryLazy',
        opts = {
            options = {
                show_close_icon = false,
                show_buffer_close_icons = false,
                truncate_names = false,
                indicator = { style = 'underline' },
                close_command = function(bufnr)
                    require('mini.bufremove').delete(bufnr, false)
                end,
                diagnostics = 'nvim_lsp',
                diagnostics_indicator = function(_, _, diag)
                    local icons = require('icons').diagnostics
                    local indicator = (diag.error and icons.ERROR .. ' ' or '') .. (diag.warning and icons.WARN or '')
                    return vim.trim(indicator)
                end,
            },
        },
        keys = {
            -- Buffer navigation.
            { '<leader>bp', '<cmd>BufferLinePick<cr>', desc = 'Pick a buffer to open' },
            { '<leader>bc', '<cmd>BufferLinePickClose<cr>', desc = 'Select a buffer to close' },
            { '<leader>bl', '<cmd>BufferLineCloseLeft<cr>', desc = 'Close buffers to the left' },
            { '<leader>br', '<cmd>BufferLineCloseRight<cr>', desc = 'Close buffers to the right' },
            { '<leader>bo', '<cmd>BufferLineCloseOthers<cr>', desc = 'Close other buffers' },
        },
    },
}
