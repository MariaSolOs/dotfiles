-- Bufferline for pretty tabs.
return {
    {
        'akinsho/bufferline.nvim',
        dependencies = 'nvim-tree/nvim-web-devicons',
        event = 'VeryLazy',
        opts = {
            options = {
                diagnostics = 'nvim_lsp',
                diagnostics_update_in_insert = false,
                diagnostics_indicator = function(_, _, diag)
                    local icons = require('helpers.icons').diagnostics
                    local ret = (diag.error and icons.Error .. diag.error .. ' ' or '')
                        .. (diag.warning and icons.Warn .. diag.warning or '')
                    return vim.trim(ret)
                end,
                -- HACK: REALLY close buffers, not just unlist them. Else minifiles
                -- won't correctly open buffers when they've been previously closed.
                close_command = 'bwipeout! %d',
                right_mouse_command = 'bwipeout! %d',
            },
        },
        init = function()
            local nmap = require('helpers.keybindings').nmap

            nmap('<leader>bo', ':BufferLinePick<cr>', { desc = 'Select a buffer to open', silent = true })
            nmap('<leader>bc', ':BufferLinePickClose<cr>', { desc = 'Select a buffer to close', silent = true })
            nmap('[b', ':BufferLineCyclePrev<cr>', 'Previous buffer')
            nmap(']b', ':BufferLineCycleNext<cr>', 'Next buffer')
            nmap('<leader>bd', ':bwipeout!<cr>', 'Delete current buffer')
            nmap('<leader>bl', ':BufferLineCloseLeft<cr>', 'Close buffers to the left')
            nmap('<leader>br', ':BufferLineCloseRight<cr>', 'Close buffers to the right')
        end,
    },
}
