-- Bufferline for pretty tabs.
return {
    {
        'akinsho/bufferline.nvim',
        event = 'VeryLazy',
        dependencies = 'echasnovski/mini.bufremove',
        opts = {
            options = {
                close_command = function(bufnr)
                    require('mini.bufremove').delete(bufnr, false)
                end,
                diagnostics = 'nvim_lsp',
                diagnostics_indicator = function(_, _, diag)
                    local icons = require('helpers.icons').diagnostics
                    local indicator = (diag.error and icons.Error .. ' ' or '') .. (diag.warning and icons.Warn or '')
                    return vim.trim(indicator)
                end,
            },
        },
        config = function(_, opts)
            local nmap = function(lhs, rhs, desc)
                vim.keymap.set('n', lhs, rhs, { desc = desc })
            end

            require('bufferline').setup(opts)

            nmap('<leader>bo', '<cmd>BufferLinePick<cr>', 'Select a buffer to open')
            nmap('<leader>bc', '<cmd>BufferLinePickClose<cr>', 'Select a buffer to close')
            nmap('[b', '<cmd>BufferLineCyclePrev<cr>', 'Previous buffer')
            nmap(']b', '<cmd>BufferLineCycleNext<cr>', 'Next buffer')
            nmap('<leader>bd', function()
                require('mini.bufremove').delete(0, true)
            end, 'Delete current buffer')
            nmap('<leader>bl', '<cmd>BufferLineCloseLeft<cr>', 'Close buffers to the left')
            nmap('<leader>br', '<cmd>BufferLineCloseRight<cr>', 'Close buffers to the right')
        end,
    },
}
