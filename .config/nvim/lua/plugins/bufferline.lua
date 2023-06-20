local nmap = require('helpers.keybindings').nmap

-- Bufferline for pretty tabs.
return {
    {
        'akinsho/bufferline.nvim',
        dependencies = 'nvim-tree/nvim-web-devicons',
        event = 'VeryLazy',
        opts = {
            options = {
                offsets = {
                    {
                        -- When toggling the explorer, place a "File Explorer" title
                        -- in the bufferline.
                        filetype = 'neo-tree',
                        text = 'File Explorer',
                        highlight = 'Directory',
                        separator = true,
                    },
                },
                diagnostics = 'nvim_lsp',
                diagnostics_update_in_insert = false,
                diagnostics_indicator = function(_, _, diag)
                    local icons = {
                        Error = ' ',
                        Warn = ' ',
                        Hint = ' ',
                        Info = ' ',
                    }
                    local ret = (diag.error and icons.Error .. diag.error .. ' ' or '')
                        .. (diag.warning and icons.Warn .. diag.warning or '')
                    return vim.trim(ret)
                end,
            },
        },
        init = function()
            nmap('<leader>bo', ':BufferLinePick<cr>', { desc = 'Select a buffer to open', silent = true })
            nmap('<leader>bc', ':BufferLinePickClose<cr>', { desc = 'Select a buffer to close', silent = true })
            nmap('[b', ':BufferLineCyclePrev<cr>', 'Previous buffer')
            nmap(']b', ':BufferLineCycleNext<cr>', 'Next buffer')
            nmap('<leader>bl', ':BufferLineCloseLeft<cr>', 'Close buffers to the left')
            nmap('<leader>br', ':BufferLineCloseRight<cr>', 'Close buffers to the right')
        end,
    },
}
