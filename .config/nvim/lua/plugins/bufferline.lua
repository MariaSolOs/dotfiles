local diagnostic_icons = require('utils.icons').diagnostics

-- Bufferline for pretty tabs.
return {
    {
        'akinsho/bufferline.nvim',
        event = { 'BufReadPre', 'BufNewFile' },
        dependencies = 'echasnovski/mini.bufremove',
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
                    local indicator = (diag.error and diagnostic_icons.Error .. ' ' or '')
                        .. (diag.warning and diagnostic_icons.Warn or '')
                    return vim.trim(indicator)
                end,
            },
        },
        config = function(_, opts)
            require('bufferline').setup(opts)

            -- Buffer navigation.
            vim.keymap.set('n', '[b', '<cmd>BufferLineCyclePrev<cr>', { desc = 'Previous buffer' })
            vim.keymap.set('n', ']b', '<cmd>BufferLineCycleNext<cr>', { desc = 'Next buffer' })
            require('which-key').register {
                ['<leader>b'] = {
                    name = '+buffers',
                    c = { '<cmd>BufferLinePickClose<cr>', 'Select a buffer to close' },
                    d = {
                        function()
                            require('mini.bufremove').delete(0, true)
                        end,
                        'Delete current buffer',
                    },
                    l = { '<cmd>BufferLineCloseLeft<cr>', 'Close buffers to the left' },
                    o = { '<cmd>BufferLinePick<cr>', 'Select a buffer to open' },
                    r = { '<cmd>BufferLineCloseRight<cr>', 'Close buffers to the right' },
                },
                -- Tab navigation.
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
