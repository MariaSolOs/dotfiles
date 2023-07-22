-- Bufferline for pretty tabs.
return {
    {
        'akinsho/bufferline.nvim',
        event = 'VeryLazy',
        opts = {
            options = {
                diagnostics = 'nvim_lsp',
                diagnostics_update_in_insert = false,
                diagnostics_indicator = function(_, _, diag)
                    local icons = require('helpers.icons').diagnostics
                    local indicator = (diag.error and icons.Error .. ' ' or '') .. (diag.warning and icons.Warn or '')
                    return vim.trim(indicator)
                end,
            },
        },
        config = function(_, opts)
            local nmap = function(lhs, rhs, desc)
                vim.keymap.set('n', lhs, rhs, { desc = desc, silent = true })
            end

            require('bufferline').setup(opts)

            nmap('<leader>bo', ':BufferLinePick<cr>', 'Select a buffer to open')
            nmap('<leader>bc', ':BufferLinePickClose<cr>', 'Select a buffer to close')
            nmap('[b', ':BufferLineCyclePrev<cr>', 'Previous buffer')
            nmap(']b', ':BufferLineCycleNext<cr>', 'Next buffer')
            nmap('<leader>bd', ':bwipeout!<cr>', 'Delete current buffer')
            nmap('<leader>bl', ':BufferLineCloseLeft<cr>', 'Close buffers to the left')
            nmap('<leader>br', ':BufferLineCloseRight<cr>', 'Close buffers to the right')
        end,
    },
}
