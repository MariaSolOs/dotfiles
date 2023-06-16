return {
    {
        'Mofiqul/dracula.nvim',
        lazy = false,
        priority = 1000,
        config = function(_, opts)
            require('dracula').setup(opts)
            vim.cmd.colorscheme 'dracula'
        end,
        opts = {
            colors = {
                bg = '#0E1419',
                fg = '#FBEAFF',
                orange = '#FFAACF'
            },
            italic_comment = true,
            overrides = {
                -- Used in git blames by Gitsigns.
                MoreMsg = { fg = '#DD58D6' }
            }
        }
    },

    -- {
    --     'folke/tokyonight.nvim',
    --     lazy = false,
    --     priority = 1000,
    --     config = function(_, opts)
    --         require('tokyonight').setup(opts)
    --         vim.cmd.colorscheme 'tokyonight-night'
    --     end,
    --     opts = {
    --         -- style = 'deep'
    --     }
    -- },
    -- {
    --     'catppuccin/nvim',
    --     lazy = false,
    --     priority = 1000,
    --     config = function(_, opts)
    --         require('catppuccin').setup(opts)
    --         vim.cmd.colorscheme 'catppuccin'
    --     end,
    --     opts = {
    --         flavour = 'mocha',
    --         color_overrides = {
    --             mocha = {
    --                 -- I prefer a darker background :)
    --                 base = '#0E1419',
    --                 crust = '#7F7489',
    --                 mantle = '#1D1A2D'
    --             }
    --         },
    --         custom_highlights = function(colors)
    --             return {
    --                 DiagnosticUnnecessary = { fg = colors.subtext1, style = { 'italic' } }
    --             }
    --         end
    --     }
    -- }
}
