-- Bufferline for pretty tabs.
return {
    {
        'akinsho/bufferline.nvim',
        dependencies = 'nvim-tree/nvim-web-devicons',
        opts = {
            options = {
                offsets = {
                    {
                        -- When toggling the explorer, place a "File Explorer" title
                        -- in the bufferline.
                        filetype = 'neo-tree',
                        text = 'File Explorer',
                        highlight = 'Directory',
                        separator = true
                    }
                },
                diagnostics = 'nvim-lsp'
            }
        },
        init = function(_)
            vim.keymap.set('n', '<leader>bp', ':BufferLinePick<cr>',
                { desc = 'Select a buffer to open', silent = true })
            vim.keymap.set('n', '<leader>bc', ':BufferLinePickClose<cr>',
                { desc = 'Select a buffer to close', silent = true })
            vim.keymap.set('n', '[b', ':BufferLineCyclePrev<cr>', { desc = 'Navigate to the previous buffer' })
            vim.keymap.set('n', ']b', ':BufferLineCycleNext<cr>', { desc = 'Navigate to the next buffer' })
            vim.keymap.set('n', '<leader>bl', ':BufferLineCloseLeft<cr>', { desc = 'Close buffers in the left' })
            vim.keymap.set('n', '<leader>br', ':BufferLineCloseRight<cr>', { desc = 'Close buffers to the right' })
        end
    }
}
