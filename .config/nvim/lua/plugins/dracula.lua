-- Colorscheme.
-- TODO(?): Vendor my own theme.
return {
    {
        'Mofiqul/dracula.nvim',
        lazy = false,
        priority = 1000,
        -- Remove unused highlight groups.
        build = 'git stash apply hl-override',
        opts = {
            colors = {
                -- Overrides.
                bg = '#0E1419',
                black = '#1E1F29',
                bright_red = '#EC6A88',
                comment = '#B08BBB',
                orange = '#FFBFA9',
                red = '#E95678',
                selection = '#3C4148',
                -- Some extra colors.
                fuchsia = '#E11299',
                grey = '#A9ABAC',
                lavender = '#6272A4',
                lilac = '#6D5978',
                transparent_blue = '#19272C',
                transparent_red = '#342231',
                transparent_yellow = '#202624',
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
                    StatuslineSpinner = { fg = colors.bright_green, bg = colors.black, bold = true },
                    StatuslineTitle = { fg = colors.bright_white, bg = colors.black, bold = true },
                })

                return vim.tbl_extend('error', statusline_groups, {
                    -- Make whitespace less prominent.
                    Whitespace = { fg = '#292d32' },

                    -- Blend line numbers with the background.
                    LineNr = { fg = colors.lilac },

                    -- Make these diagnostics different from regular comments.
                    DiagnosticUnnecessary = { fg = colors.white, italic = true },

                    -- Nicer diffs.
                    DiffAdd = { fg = colors.bright_green, bold = true },
                    DiffChange = { fg = colors.orange, bold = true },
                    DiffDelete = { fg = colors.bright_red, bold = true },
                    DiffText = { fg = colors.bright_white, bold = true },

                    -- Make window separators more visible.
                    VertSplit = { fg = colors.white },

                    -- Smoother bufferline.
                    BufferLineFill = { bg = colors.bg },
                    BufferLineSeparator = { fg = colors.bg },

                    -- Nicer completion UI.
                    CmpItemKind = { bg = 'NONE' },
                    CmpItemAbbr = { fg = colors.white, bg = 'NONE' },
                    CmpItemAbbrMatch = { fg = colors.cyan, bg = 'NONE' },
                    CmpItemAbbrDeprecated = { strikethrough = true },
                    CmpItemMenu = { fg = colors.grey },
                    Pmenu = { fg = colors.white, bg = colors.transparent_blue },
                    PmenuSel = { fg = colors.cyan, bg = colors.selection },
                    PmenuSbar = { bg = colors.transparent_blue },

                    -- Make these hints different from comments/regular code.
                    LspInlayHint = { fg = colors.lavender, italic = true },

                    -- Background for folded lines.
                    Folded = { bg = colors.black },

                    -- Super visible cursor.
                    Cursor = { fg = '#000000', bg = colors.white },

                    -- Command line.
                    MoreMsg = { fg = colors.bright_white, bold = true },
                    MsgArea = { fg = colors.cyan },
                    MsgSeparator = { fg = colors.lilac },

                    -- Make search a bit more visible for flash.
                    IncSearch = { fg = '#000000', bg = colors.fuchsia },
                    Substitute = { fg = colors.fuchsia, bg = colors.orange, bold = true },

                    -- When triggering flash, use a white font and make everything in the backdrop italic.
                    FlashPrompt = { link = 'Normal' },
                    FlashBackdrop = { italic = true },

                    -- Make these titles more visible.
                    MiniClueTitle = { bold = true, fg = colors.cyan },
                    MiniFilesTitleFocused = { bold = true, fg = colors.cyan },

                    -- Nicer highlights for the word under the cursor.
                    LspReferenceRead = { bg = colors.transparent_blue },
                    LspReferenceWrite = { bg = colors.transparent_red },
                    LspReferenceText = {},

                    -- Active parameter in signature help.
                    LspSignatureActiveParameter = { bold = true, underline = true, sp = colors.fg },

                    -- Nicer yanky highlights.
                    YankyPut = { link = 'Visual' },
                    YankyYanked = { link = 'Visual' },

                    -- Add backgrounds to diagnostic virtual text.
                    DiagnosticVirtualTextError = { fg = colors.red, bg = colors.transparent_red },
                    DiagnosticVirtualTextWarn = { fg = colors.yellow, bg = colors.transparent_yellow },
                    DiagnosticVirtualTextInfo = { fg = colors.cyan, bg = colors.transparent_blue },
                    DiagnosticVirtualTextHint = { fg = colors.cyan, bg = colors.transparent_blue },

                    -- Highlight for the Treesitter sticky context.
                    TreesitterContextBottom = { underline = true, sp = colors.lilac },

                    -- Winbar styling.
                    WinBar = { fg = colors.fg, bg = colors.black },
                    WinBarDir = { fg = colors.bright_magenta, bg = colors.black, italic = true },
                    WinBarSeparator = { fg = colors.green, bg = colors.black },

                    -- Virtual text for DAP.
                    NvimDapVirtualText = { fg = colors.lavender, underline = true },

                    -- Fzf overrides.
                    FzfLuaBorder = { fg = colors.comment },
                    FzfLuaHeaderText = { fg = colors.pink },
                    FzfLuaHeaderBind = { fg = colors.lavender },
                    FzfLuaPreviewTitle = { fg = colors.fg },
                    FzfLuaSearch = { bg = colors.transparent_red },

                    -- Mason window.
                    MasonMuted = { fg = colors.bright_cyan },

                    -- TODOs and notes.
                    MiniHipatternsTodo = { fg = colors.bg, bg = colors.cyan, bold = true },
                    MiniHipatternsNote = { fg = colors.bg, bg = colors.bright_green, bold = true },
                    MiniHipatternsHack = { fg = colors.bg, bg = colors.orange, bold = true },

                    -- Quickfix window.
                    qfPath = { fg = colors.bright_blue },
                    qfPosition = { fg = colors.pink, underline = true },
                    QuickFixLine = { italic = true, bg = colors.transparent_red },
                    BqfPreviewRange = { fg = colors.bg, bg = colors.bright_magenta },

                    -- Overseeer overrides.
                    OverseerComponent = { link = '@keyword' },
                })
            end,
        },
        config = function(_, opts)
            require('dracula').setup(opts)
            vim.cmd.colorscheme 'dracula-soft'
        end,
    },
}
