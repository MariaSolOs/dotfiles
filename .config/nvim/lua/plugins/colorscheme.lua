return {
    {
        'MariaSolOs/miss-dracula.nvim',
        lazy = false,
        priority = 1000,
        config = function(_, opts)
            require('miss-dracula').setup(opts)
            vim.cmd.colorscheme 'miss-dracula'
        end,
        opts = {
            italic_comment = true,
            overrides = function(colors)
                return {
                    -- Make these diagnostics different from regular comments.
                    DiagnosticUnnecessary = { fg = colors.white, italic = true },

                    -- Use a different color for inlay hints to make them different from comments.
                    LspInlayHint = { fg = '#6272A4', italic = true },

                    -- Group used by Gitsigns and Noice. Make it stand out.
                    MoreMsg = { fg = '#E11299' },

                    -- Make search a bit more visible for flash.
                    IncSearch = { fg = '#000000', bg = '#E11299' },
                    Substitute = { fg = '#E11299', bg = colors.orange, bold = true },

                    -- Make the title of the focused window in the file explorer more visible.
                    MiniFilesTitleFocused = { bold = true, fg = colors.cyan },

                    -- Highlights for the progress bar.
                    NoiceFormatProgressDone = { bg = '#27E1C1', fg = '#000000' },
                    NoiceLspProgressSpinner = { fg = '#27E1C1' },
                    NoiceFormatProgressTodo = { link = 'NonText' },

                    -- Nicer highlights for the word under the cursor.
                    IlluminatedWordRead = { bg = '#364852' },
                    IlluminatedWordWrite = { bg = '#342231' },
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
