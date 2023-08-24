-- Colorscheme.
return {
    {
        'Mofiqul/dracula.nvim',
        lazy = false,
        priority = 1000,
        opts = {
            colors = {
                bg = '#0E1419',
                comment = '#B08BBB',
                orange = '#FFBFA9',
                red = '#E95678',
                bright_red = '#EC6A88',
            },
            italic_comment = true,
            overrides = function(colors)
                return {
                    -- Make the separations between windows more visible.
                    VertSplit = { fg = colors.white },

                    -- Make whitespace less prominent.
                    Whitespace = { fg = '#292d32' },

                    -- Make these diagnostics different from regular comments.
                    DiagnosticUnnecessary = { fg = colors.white, italic = true },

                    -- Smoother backgrounds in the completion menu.
                    CmpItemKind = { fg = colors.white, bg = 'NONE' },
                    CmpItemAbbr = { fg = colors.white, bg = 'NONE' },
                    CmpItemAbbrMatch = { fg = colors.cyan, bg = 'NONE' },

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
                    NoiceLspProgressSpinner = { fg = '#E11299', bg = colors.black },
                    NoiceLspProgressTitle = { fg = colors.white, bg = colors.black },
                    NoiceLspProgressClient = { fg = colors.cyan, bg = colors.black },

                    -- Diff highlights.
                    DiffAdd = { fg = colors.bright_green, bold = true },
                    DiffChange = { fg = colors.orange, bold = true },
                    DiffDelete = { fg = colors.bright_red, bold = true },
                    DiffText = { fg = colors.bright_white, bold = true },

                    -- Nicer highlights for the word under the cursor.
                    IlluminatedWordRead = { bg = '#19272C' },
                    IlluminatedWordWrite = { bg = '#342231' },

                    -- Highlight for the Treesitter sticky context.
                    TreesitterContextBottom = { underline = true, sp = colors.comment },

                    -- Winbar styling.
                    WinBar = { bold = false },
                    DropBarMenuCurrentContext = { link = 'Normal' },

                    -- Virtual text for DAP.
                    NvimDapVirtualText = { fg = '#6272A4', underline = true },

                    -- Fzf overrides.
                    FzfLuaBorder = { fg = colors.comment },
                    FzfLuaSearch = { link = 'IlluminatedWordWrite' },
                    FzfLuaHeaderText = { fg = colors.pink },
                    FzfLuaPreviewTitle = { fg = colors.fg },
                    FzfLuaHeaderBind = { fg = '#6272A4' },

                    -- Mason window.
                    MasonMuted = { fg = colors.bright_cyan },

                    -- TODOs and notes.
                    MiniHipatternsTodo = { fg = colors.bg, bg = colors.cyan, bold = true },
                    MiniHipatternsNote = { fg = colors.bg, bg = colors.bright_green, bold = true },

                    -- Quickfix window.
                    qfPath = { fg = colors.bright_blue },
                    qfPosition = { fg = colors.pink, underline = true },
                    QuickFixLine = { italic = true, bg = '#342231' },
                    BqfPreviewRange = { link = 'Search' },
                }
            end,
        },
        config = function(_, opts)
            require('dracula').setup(opts)
            vim.cmd.colorscheme 'dracula-soft'
        end,
    },
}
