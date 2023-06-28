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

                    -- Make these virtual text thingies different from comments/regular code.
                    LspInlayHint = { fg = '#6272A4', italic = true },
                    LspCodeLens = { fg = '#6272A4' },
                    LspCodeLensSeparator = { fg = '#6272A4' },

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

                    -- When triggering flash, make everything in the backdrop italic.
                    FlashBackdrop = { italic = true },
                }
            end,
        },
    },
}
