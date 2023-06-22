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
                    -- Group used by Gitsigns and Noice. Make it stand out.
                    MoreMsg = { fg = '#E11299' },
                    -- Make search a bit more visible for flash.
                    IncSearch = { fg = '#000000', bg = '#E11299' },
                    Substitute = { fg = '#E11299', bg = colors.orange, bold = true },
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
                    -- Make the title of the focused window in the file explorer more visible.
                    MiniFilesTitleFocused = { bold = true, fg = colors.cyan },
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
