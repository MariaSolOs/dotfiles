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
                orange = '#FFAACF',
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

                    -- Make the title of the focused window in the file explorer more visible.
                    MiniFilesTitleFocused = { bold = true, fg = colors.cyan },

                    -- Highlights for the progress bar.
                    NoiceFormatProgressDone = { bg = '#27E1C1', fg = '#000000' },
                    NoiceLspProgressSpinner = { fg = '#27E1C1' },
                    NoiceFormatProgressTodo = { link = 'NonText' },

                    -- Nicer highlights for the word under the cursor.
                    IlluminatedWordRead = { bg = '#19272C' },
                    IlluminatedWordWrite = { bg = '#342231' },

                    -- When triggering flash, make everything in the backdrop italic.
                    FlashBackdrop = { italic = true },

                    -- This UI is hideous by default. Make it more Draculy.
                    DapUIPlayPause = { fg = colors.bright_green },
                    DapUIRestart = { fg = colors.green },
                    DapUIStop = { fg = colors.red },
                    DapUIStepOver = { fg = colors.cyan },
                    DapUIStepInto = { fg = colors.cyan },
                    DapUIStepOut = { fg = colors.cyan },
                    DapUIStepBack = { fg = colors.cyan },
                    DapUIType = { fg = colors.bright_blue },
                    DapUIScope = { fg = colors.bright_cyan },
                    DapUIModifiedValue = { fg = colors.bright_cyan, bold = true },
                    DapUIDecoration = { fg = colors.bright_cyan },
                    DapUIThread = { fg = colors.bright_green },
                    DapUIStoppedThread = { fg = colors.bright_cyan },
                    DapUISource = { fg = colors.bright_blue },
                    DapUILineNumber = { fg = colors.bright_cyan },
                    DapUIFloatBorder = { fg = colors.bright_cyan },
                    DapUIWatchesEmpty = { fg = colors.pink },
                    DapUIWatchesValue = { fg = colors.bright_green },
                    DapUIWatchesError = { fg = colors.pink },
                    DapUIBreakpointsPath = { fg = colors.bright_cyan },
                    DapUIBreakpointsInfo = { fg = colors.bright_green },
                    DapUIBreakpointsCurrentLine = { fg = colors.bright_green, bold = true },
                    DapStoppedLine = { default = true, link = 'Visual' },
                    DapUIWinSelect = { fg = colors.bright_cyan, bold = true },

                    -- Rainbow delimiter colors
                    RainbowDelimiterRed = { fg = '#F266AB', ctermfg = 'Red' },
                    RainbowDelimiterOrange = { fg = '#FFB84C', ctermfg = 'White' },
                    RainbowDelimiterYellow = { fg = '#FFF56F', ctermfg = 'Yellow' },
                    RainbowDelimiterGreen = { fg = '#87E58E', ctermfg = 'Green' },
                    RainbowDelimiterCyan = { fg = '#A7DFEF', ctermfg = 'Cyan' },
                    RainbowDelimiterBlue = { fg = '#0079FF', ctermfg = 'Blue' },
                    RainbowDelimiterViolet = { fg = '#A459D1', ctermfg = 'Magenta' },
                }
            end,
        },
    },
}
