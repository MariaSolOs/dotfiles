-- Surround selections, add quotes, etc.
return {
    {
        'kylechui/nvim-surround',
        event = 'VeryLazy',
        init = function()
            -- Disable the default keymaps.
            vim.g.nvim_surround_no_mappings = true
        end,
        config = function()
            require('nvim-surround').setup()

            vim.keymap.set('n', 'yz', '<Plug>(nvim-surround-normal)', {
                desc = 'Add a surrounding pair around a motion (normal mode)',
            })
            vim.keymap.set('n', 'yzz', '<Plug>(nvim-surround-normal-cur)', {
                desc = 'Add a surrounding pair around the current line (normal mode)',
            })
            vim.keymap.set('x', 'Z', '<Plug>(nvim-surround-visual)', {
                desc = 'Add a surrounding pair around a visual selection',
            })
            vim.keymap.set('n', 'ds', '<Plug>(nvim-surround-delete)', {
                desc = 'Delete a surrounding pair',
            })
            vim.keymap.set('n', 'cs', '<Plug>(nvim-surround-change)', {
                desc = 'Change a surrounding pair',
            })
        end,
    },
}
