-- Colorscheme.
-- Using my own fork because the original one is getting bloated with plugins
-- I don't use.
return {
    {
        'MariaSolOs/dracula.nvim',
        lazy = false,
        priority = 1000,
        opts = {
            -- Some extra colors.
            colors = {
                fuchsia = '#E11299',
                grey = '#A9ABAC',
                lavender = '#6272A4',
            },
            italic_comment = true,
            overrides = function(colors)
                local statusline_groups = {}
                for mode, color in pairs {
                    Normal = 'purple',
                    Pending = 'pink',
                    Visual = 'yellow',
                    Insert = 'green',
                    Command = 'cyan',
                    Other = 'orange',
                } do
                    statusline_groups['StatuslineMode' .. mode] = { fg = colors.black, bg = colors[color] }
                    statusline_groups['StatuslineModeSeparator' .. mode] = { fg = colors[color], bg = colors.black }
                end
                statusline_groups = vim.tbl_extend('error', statusline_groups, {
                    StatuslineItalic = { fg = colors.grey, bg = colors.black, italic = true },
                    StatuslineTitle = { fg = colors.bright_white, bg = colors.black, bold = true },
                    StatuslineNoice = { fg = colors.yellow, bg = colors.black, underline = true },
                })

                return vim.tbl_extend('error', statusline_groups, {
                    -- Make whitespace less prominent.
                    Whitespace = { fg = '#292d32' },

                    -- Make these diagnostics different from regular comments.
                    DiagnosticUnnecessary = { fg = colors.white, italic = true },

                    -- Greyish description in the completion menu.
                    CmpItemMenu = { fg = colors.grey },

                    -- Make these virtual text thingies different from comments/regular code.
                    LspInlayHint = { fg = colors.lavender, italic = true },

                    -- Group used by Gitsigns and Noice. Make it stand out.
                    MoreMsg = { fg = colors.fuchsia },

                    -- Make search a bit more visible for flash.
                    IncSearch = { fg = '#000000', bg = colors.fuchsia },
                    Substitute = { fg = colors.fuchsia, bg = colors.orange, bold = true },

                    -- When triggering flash, make everything in the backdrop italic.
                    FlashBackdrop = { italic = true },

                    -- Make the title of the focused window in the file explorer more visible.
                    MiniFilesTitleFocused = { bold = true, fg = colors.cyan },

                    -- Notifications.
                    MsgArea = { fg = colors.bright_magenta },

                    -- Nicer highlights for the word under the cursor.
                    IlluminatedWordRead = { bg = '#19272C' },
                    IlluminatedWordWrite = { bg = '#342231' },

                    -- Highlight for the Treesitter sticky context.
                    TreesitterContextBottom = { underline = true, sp = colors.comment },

                    -- Winbar styling.
                    WinBar = { bold = false },
                    DropBarMenuCurrentContext = { link = 'Normal' },

                    -- Virtual text for DAP.
                    NvimDapVirtualText = { fg = colors.lavender, underline = true },

                    -- Fzf overrides.
                    FzfLuaBorder = { fg = colors.comment },
                    FzfLuaSearch = { link = 'IlluminatedWordWrite' },
                    FzfLuaHeaderText = { fg = colors.pink },
                    FzfLuaPreviewTitle = { fg = colors.fg },
                    FzfLuaHeaderBind = { fg = colors.lavender },

                    -- Mason window.
                    MasonMuted = { fg = colors.bright_cyan },

                    -- TODOs and notes.
                    MiniHipatternsTodo = { fg = colors.bg, bg = colors.cyan, bold = true },
                    MiniHipatternsNote = { fg = colors.bg, bg = colors.bright_green, bold = true },

                    -- Quickfix window.
                    qfPath = { fg = colors.bright_blue },
                    qfPosition = { fg = colors.pink, underline = true },
                    QuickFixLine = { italic = true, bg = '#342231' },
                    BqfPreviewRange = { fg = colors.bg, bg = colors.bright_magenta },
                })
            end,
        },
        config = function(_, opts)
            require('dracula').setup(opts)
            vim.cmd.colorscheme 'dracula-soft'
        end,
    },
}
