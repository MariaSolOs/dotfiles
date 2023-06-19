-- Rainbow brackets.
return {
    {
        'HiPhish/nvim-ts-rainbow2',
        dependencies = 'nvim-treesitter/nvim-treesitter',
        config = function()
            -- Set up the colors to use.
            vim.api.nvim_set_hl(0, 'TSRainbowRed', { fg = '#F266AB', ctermfg = 'Red' })
            vim.api.nvim_set_hl(0, 'TSRainbowOrange', { fg = '#FFB84C', ctermfg = 'White' })
            vim.api.nvim_set_hl(0, 'TSRainbowYellow', { fg = '#FFF56D', ctermfg = 'Yellow' })
            vim.api.nvim_set_hl(0, 'TSRainbowGreen', { fg = '#87E58E', ctermfg = 'Green' })
            vim.api.nvim_set_hl(0, 'TSRainbowCyan', { fg = '#A7DFEF', ctermfg = 'Cyan' })
            vim.api.nvim_set_hl(0, 'TSRainbowBlue', { fg = '#0079FF', ctermfg = 'Blue' })
            vim.api.nvim_set_hl(0, 'TSRainbowViolet', { fg = '#A459D1', ctermfg = 'Magenta' })

            require('nvim-treesitter.configs').setup {
                rainbow = { enable = true },
            }
        end,
    },
}
