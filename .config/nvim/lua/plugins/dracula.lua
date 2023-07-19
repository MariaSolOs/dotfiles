-- Colorscheme.
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
                orange = '#FFBFA9',
            },
            italic_comment = true,
            overrides = function(colors)
                return {
                    -- Make these diagnostics different from regular comments.
                    DiagnosticUnnecessary = { fg = colors.white, italic = true },

                    -- Make these virtual text thingies different from comments/regular code.
                    LspInlayHint = { fg = '#6272A4', italic = true },

                    -- Group used by Gitsigns and Noice. Make it stand out.
                    MoreMsg = { fg = '#E11299' },

                    -- Make search a bit more visible for flash.
                    IncSearch = { fg = '#000000', bg = '#E11299' },
                    Substitute = { fg = '#E11299', bg = colors.orange, bold = true },

                    -- When triggering flash, make everything in the backdrop italic.
                    FlashBackdrop = { italic = true },

                    -- Make the title of the focused window in the file explorer more visible.
                    MiniFilesTitleFocused = { bold = true, fg = colors.cyan },

                    -- Smoother Bufferline tabs.
                    BufferLineFill = { bg = colors.bg },
                    BufferLineSeparator = { fg = colors.bg },

                    -- Highlights for the LSP Lualine component.
                    NoiceLspProgressSpinner = { fg = '#27E1C1', bg = colors.black },
                    NoiceLspProgressTitle = { fg = colors.white, bg = colors.black },
                    NoiceLspProgressClient = { fg = colors.cyan, bg = colors.black },

                    -- Nicer highlights for the word under the cursor.
                    IlluminatedWordRead = { bg = '#19272C' },
                    IlluminatedWordWrite = { bg = '#342231' },

                    -- Highlight for the Treesitter sticky context.
                    TreesitterContextBottom = { underline = true, sp = colors.comment },
                }
            end,
        },
    },
}
