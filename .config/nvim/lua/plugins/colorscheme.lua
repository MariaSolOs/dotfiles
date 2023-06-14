-- Color theme.
return {
    -- {
    --     'Mofiqul/dracula.nvim',
    --     lazy = false,
    --     priority = 1000,
    --     config = function(_, opts)
    --         require('dracula').setup(opts)
    --         vim.cmd.colorscheme 'dracula'
    --     end,
    --     opts = {
    --         colors = {
    --             bg = '#0E1419',
    --             fg = '#FBEAFF',
    --             orange = '#FFAACF'
    --         },
    --         italic_comment = true,
    --     }
    -- }
    {
        'catppuccin/nvim',
        lazy = false,
        priority = 1000,
        config = function(_, opts)
            require('catppuccin').setup(opts)
            vim.cmd.colorscheme 'catppuccin'
        end,
        opts = {
            flavour = 'mocha',
            color_overrides = {
                mocha = {
                    -- I prefer a darker background :)
                    base = '#0E1419',
                }
            },
            custom_highlights = function(colors)
                return {
                    -- Make the file explorer purple-ish.
                    NvimTreeFolderName = { fg = colors.mauve },
                    NvimTreeFolderIcon = { fg = colors.mauve },
                    NvimTreeOpenedFolderName = { fg = colors.mauve },
                    NvimTreeEmptyFolderName = { fg = colors.mauve },

                    -- Make variables pink-ish.
                    ['@variable'] = { fg = colors.pink },
                    ['@parameter'] = { fg = colors.pink },

                    DiagnosticUnnecessary = { fg = colors.subtext1, style = { 'italic' } }
                }
            end
        }
    }
}
