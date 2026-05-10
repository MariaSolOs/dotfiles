local add_on_event = require('vim-pack').add_on_event

-- Pretty bufferline.
add_on_event('VimEnter', {
    {
        src = 'akinsho/bufferline.nvim',
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
        on_setup = function()
            -- Buffer navigation.
            vim.keymap.set('n', '<leader>bp', '<cmd>BufferLinePick<cr>', { desc = 'Pick a buffer to open' })
            vim.keymap.set('n', '<leader>bc', '<cmd>BufferLinePickClose<cr>', { desc = 'Select a buffer to close' })
            vim.keymap.set('n', '<leader>bo', '<cmd>BufferLineCloseOthers<cr>', { desc = 'Close other buffers' })
        end,
    },
})
