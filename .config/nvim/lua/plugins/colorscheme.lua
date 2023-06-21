return {
    {
        'Mofiqul/dracula.nvim',
        lazy = false,
        priority = 1000,
        config = function(_, opts)
            require('dracula').setup(opts)
            vim.cmd.colorscheme 'dracula-soft'
        end,
        opts = {
            colors = {
                bg = '#0E1419',
                comment = '#B08BBB',
                orange = '#FFAACF',
            },
            italic_comment = true,
            overrides = function(colors)
                return {
                    -- Used in git blames by Gitsigns.
                    MoreMsg = { fg = '#E11299' },
                    DiagnosticUnnecessary = { fg = colors.white, italic = true },
                    IncSearch = { fg = '#000000', bg = '#E11299' },
                    Substitute = { fg = '#E11299', bg = colors.orange, bold = true },
                }
            end,
        },
    },

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
    --             all = {
    --                 -- I prefer a darker background :)
    --                 base = '#0E1419',
    --                 mantle = '#0E1419',
    --                 crust = '#2D323D',
    --             },
    --         },
    --         custom_highlights = function(colors)
    --             return {
    --                 Comment = { fg = '#CDA6C3' },
    --                 DiagnosticUnnecessary = { fg = colors.subtext1, style = { 'italic' } },
    --             }
    --         end,
    --     },
    -- },
}
