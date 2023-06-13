-- Bufferline for pretty tabs.
return {
    {
        'akinsho/bufferline.nvim',
        dependencies = 'nvim-tree/nvim-web-devicons',
        opts = {
            options = {
                offsets = {
                    {
                        filetype = 'NvimTree',
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
        end
    }
}
