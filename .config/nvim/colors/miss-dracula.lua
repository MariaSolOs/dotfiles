-- My own version of Dracula.

-- Reset highlighting.
vim.cmd.highlight 'clear'
if vim.fn.exists 'syntax_on' then
    vim.cmd.syntax 'reset'
end
vim.o.termguicolors = true
vim.g.colors_name = 'miss-dracula'

local colors = {
    bg = '#0E1419',
    black = '#000000',
    bright_blue = '#D0B5F3',
    bright_cyan = '#BCF4F5',
    bright_green = '#97EDA2',
    bright_magenta = '#E7A1D7',
    bright_red = '#EC6A88',
    bright_white = '#FFFFFF',
    bright_yellow = '#F6F6B6',
    comment = '#B08BBB',
    cyan = '#A7DFEF',
    fg = '#F6F6F5',
    fuchsia = '#E11299',
    green = '#87E58E',
    grey = '#A9ABAC',
    gutter_fg = '#4B5263',
    lavender = '#6272A4',
    lilac = '#6D5978',
    menu = '#21222C',
    nontext = '#3B4048',
    orange = '#FFBFA9',
    pink = '#E48CC1',
    purple = '#BAA0E8',
    red = '#E95678',
    selection = '#3C4148',
    transparent_black = '#1E1F29',
    transparent_blue = '#19272C',
    transparent_green = '#22372c',
    transparent_red = '#342231',
    transparent_yellow = '#202624',
    visual = '#3E4452',
    white = '#F6F6F5',
    yellow = '#E8EDA2',
}

-- Terminal colors.
vim.g.terminal_color_0 = colors.transparent_black
vim.g.terminal_color_1 = colors.red
vim.g.terminal_color_2 = colors.green
vim.g.terminal_color_3 = colors.yellow
vim.g.terminal_color_4 = colors.purple
vim.g.terminal_color_5 = colors.pink
vim.g.terminal_color_6 = colors.cyan
vim.g.terminal_color_7 = colors.white
vim.g.terminal_color_8 = colors.selection
vim.g.terminal_color_9 = colors.bright_red
vim.g.terminal_color_10 = colors.bright_green
vim.g.terminal_color_11 = colors.bright_yellow
vim.g.terminal_color_12 = colors.bright_blue
vim.g.terminal_color_13 = colors.bright_magenta
vim.g.terminal_color_14 = colors.bright_cyan
vim.g.terminal_color_15 = colors.bright_white
vim.g.terminal_color_background = colors.bg
vim.g.terminal_color_foreground = colors.fg

-- Groups used for my statusline.
---@type table<string, vim.api.keyset.highlight>
local statusline_groups = {}
for mode, color in pairs {
    Normal = 'purple',
    Pending = 'pink',
    Visual = 'yellow',
    Insert = 'green',
    Command = 'cyan',
    Other = 'orange',
} do
    statusline_groups['StatuslineMode' .. mode] = { fg = colors.transparent_black, bg = colors[color] }
    statusline_groups['StatuslineModeSeparator' .. mode] = { fg = colors[color], bg = colors.transparent_black }
end
statusline_groups = vim.tbl_extend('error', statusline_groups, {
    StatuslineItalic = { fg = colors.grey, bg = colors.transparent_black, italic = true },
    StatuslineSpinner = { fg = colors.bright_green, bg = colors.transparent_black, bold = true },
    StatuslineTitle = { fg = colors.bright_white, bg = colors.transparent_black, bold = true },
})

---@type table<string, vim.api.keyset.highlight>
local groups = vim.tbl_extend('error', statusline_groups, {
    -- Builtins.
    Boolean = { fg = colors.cyan },
    Character = { fg = colors.green },
    ColorColumn = { bg = colors.selection },
    Comment = { fg = colors.comment, italic = true },
    Conceal = { fg = colors.comment },
    Conditional = { fg = colors.pink },
    Constant = { fg = colors.yellow },
    Cursor = { fg = colors.black, bg = colors.white },
    CursorColumn = { bg = colors.transparent_black },
    CursorLine = { bg = colors.selection },
    CursorLineNr = { fg = colors.lilac, bold = true },
    Define = { fg = colors.purple },
    Directory = { fg = colors.cyan },
    EndOfBuffer = { fg = colors.bg },
    Error = { fg = colors.bright_red },
    ErrorMsg = { fg = colors.bright_red },
    FoldColumn = {},
    Folded = { bg = colors.transparent_black },
    Function = { fg = colors.yellow },
    Identifier = { fg = colors.cyan },
    IncSearch = { fg = colors.black, bg = colors.fuchsia },
    Include = { fg = colors.purple },
    Keyword = { fg = colors.cyan },
    Label = { fg = colors.cyan },
    LineNr = { fg = colors.lilac },
    Macro = { fg = colors.purple },
    MatchParen = { fg = colors.fg, underline = true },
    NonText = { fg = colors.nontext },
    Normal = { fg = colors.fg, bg = colors.bg },
    NormalFloat = { fg = colors.fg, bg = colors.bg },
    Number = { fg = colors.orange },
    Pmenu = { fg = colors.white, bg = colors.transparent_blue },
    PmenuSbar = { bg = colors.transparent_blue },
    PmenuSel = { fg = colors.cyan, bg = colors.selection },
    PmenuThumb = { bg = colors.selection },
    PreCondit = { fg = colors.cyan },
    PreProc = { fg = colors.yellow },
    Question = { fg = colors.purple },
    Repeat = { fg = colors.pink },
    Search = { fg = colors.bg, bg = colors.orange },
    SignColumn = { bg = colors.bg },
    Special = { fg = colors.green, italic = true },
    SpecialComment = { fg = colors.comment, italic = true },
    SpecialKey = { fg = colors.nontext },
    SpellBad = { fg = colors.bright_red, underline = true },
    SpellCap = { fg = colors.yellow },
    SpellLocal = { fg = colors.yellow },
    SpellRare = { fg = colors.yellow },
    Statement = { fg = colors.purple },
    StatusLine = { fg = colors.white, bg = colors.transparent_black },
    StorageClass = { fg = colors.pink },
    Structure = { fg = colors.yellow },
    Substitute = { fg = colors.fuchsia, bg = colors.orange, bold = true },
    Title = { fg = colors.cyan },
    Todo = { fg = colors.purple, bold = true, italic = true },
    Type = { fg = colors.cyan },
    TypeDef = { fg = colors.yellow },
    Underlined = { fg = colors.cyan, underline = true },
    VertSplit = { fg = colors.white },
    Visual = { bg = colors.visual },
    VisualNOS = { fg = colors.visual },
    WarningMsg = { fg = colors.yellow },
    WildMenu = { fg = colors.transparent_black, bg = colors.white },

    -- TreeSitter.
    ['@annotation'] = { fg = colors.yellow },
    ['@attribute'] = { fg = colors.cyan },
    ['@boolean'] = { fg = colors.purple },
    ['@character'] = { fg = colors.green },
    ['@conditional'] = { fg = colors.pink },
    ['@constant'] = { fg = colors.purple },
    ['@constant.builtin'] = { fg = colors.purple },
    ['@constant.macro'] = { fg = colors.cyan },
    ['@constructor'] = { fg = colors.cyan },
    ['@error'] = { fg = colors.bright_red },
    ['@exception'] = { fg = colors.purple },
    ['@field'] = { fg = colors.orange },
    ['@float'] = { fg = colors.green },
    ['@function'] = { fg = colors.green },
    ['@function.builtin'] = { fg = colors.cyan },
    ['@function.macro'] = { fg = colors.green },
    ['@include'] = { fg = colors.pink },
    ['@keyword'] = { fg = colors.pink },
    ['@keyword.function'] = { fg = colors.cyan },
    ['@keyword.function.ruby'] = { fg = colors.pink },
    ['@keyword.operator'] = { fg = colors.pink },
    ['@label'] = { fg = colors.cyan },
    ['@method'] = { fg = colors.green },
    ['@namespace'] = { fg = colors.orange },
    ['@number'] = { fg = colors.purple },
    ['@operator'] = { fg = colors.pink },
    ['@parameter'] = { fg = colors.orange },
    ['@parameter.reference'] = { fg = colors.orange },
    ['@property'] = { fg = colors.purple },
    ['@punctuation.bracket'] = { fg = colors.fg },
    ['@punctuation.delimiter'] = { fg = colors.fg },
    ['@punctuation.special'] = { fg = colors.cyan },
    ['@repeat'] = { fg = colors.pink },
    ['@string'] = { fg = colors.yellow },
    ['@string.escape'] = { fg = colors.cyan },
    ['@string.regex'] = { fg = colors.red },
    ['@structure'] = { fg = colors.purple },
    ['@symbol'] = { fg = colors.purple },
    ['@tag'] = { fg = colors.cyan },
    ['@tag.attribute'] = { fg = colors.green },
    ['@tag.delimiter'] = { fg = colors.cyan },
    ['@text'] = { fg = colors.orange },
    ['@text.emphasis'] = { fg = colors.yellow, italic = true },
    ['@text.literal'] = { fg = colors.yellow },
    ['@text.reference'] = { fg = colors.orange, bold = true },
    ['@text.strong'] = { fg = colors.orange, bold = true },
    ['@text.title'] = { fg = colors.pink, bold = true },
    ['@text.underline'] = { fg = colors.orange },
    ['@text.uri'] = { fg = colors.yellow, italic = true },
    ['@type'] = { fg = colors.bright_cyan },
    ['@type.builtin'] = { fg = colors.cyan, italic = true },
    ['@type.qualifier'] = { fg = colors.pink },
    ['@variable'] = { fg = colors.fg },
    ['@variable.builtin'] = { fg = colors.purple },

    -- Semantic tokens.
    ['@class'] = { fg = colors.cyan },
    ['@decorator'] = { fg = colors.cyan },
    ['@enum'] = { fg = colors.cyan },
    ['@enumMember'] = { fg = colors.purple },
    ['@event'] = { fg = colors.cyan },
    ['@interface'] = { fg = colors.cyan },
    ['@lsp.type.class'] = { fg = colors.cyan },
    ['@lsp.type.decorator'] = { fg = colors.green },
    ['@lsp.type.enum'] = { fg = colors.cyan },
    ['@lsp.type.enumMember'] = { fg = colors.purple },
    ['@lsp.type.function'] = { fg = colors.green },
    ['@lsp.type.interface'] = { fg = colors.cyan },
    ['@lsp.type.macro'] = { fg = colors.cyan },
    ['@lsp.type.method'] = { fg = colors.green },
    ['@lsp.type.namespace'] = { fg = colors.orange },
    ['@lsp.type.parameter'] = { fg = colors.orange },
    ['@lsp.type.property'] = { fg = colors.purple },
    ['@lsp.type.struct'] = { fg = colors.cyan },
    ['@lsp.type.type'] = { fg = colors.bright_cyan },
    ['@lsp.type.variable'] = { fg = colors.fg },
    ['@modifier'] = { fg = colors.cyan },
    ['@regexp'] = { fg = colors.yellow },
    ['@struct'] = { fg = colors.cyan },
    ['@typeParameter'] = { fg = colors.cyan },

    -- LSP.
    DiagnosticDeprecated = { strikethrough = true, fg = colors.fg },
    DiagnosticError = { fg = colors.red },
    DiagnosticHint = { fg = colors.cyan },
    DiagnosticInfo = { fg = colors.cyan },
    DiagnosticWarn = { fg = colors.yellow },
    DiagnosticUnderlineError = { undercurl = true, sp = colors.red },
    DiagnosticUnderlineHint = { undercurl = true, sp = colors.cyan },
    DiagnosticUnderlineInfo = { undercurl = true, sp = colors.cyan },
    DiagnosticUnderlineWarn = { undercurl = true, sp = colors.yellow },
    DiagnosticUnnecessary = { fg = colors.white, italic = true },
    DiagnosticVirtualTextError = { fg = colors.red, bg = colors.transparent_red },
    DiagnosticVirtualTextHint = { fg = colors.cyan, bg = colors.transparent_blue },
    DiagnosticVirtualTextInfo = { fg = colors.cyan, bg = colors.transparent_blue },
    DiagnosticVirtualTextWarn = { fg = colors.yellow, bg = colors.transparent_yellow },
    LspCodeLens = { fg = colors.cyan },
    LspInlayHint = { fg = colors.lavender, italic = true },
    LspReferenceRead = { bg = colors.transparent_blue },
    LspReferenceText = {},
    LspReferenceWrite = { bg = colors.transparent_red },
    LspSignatureActiveParameter = { bold = true, underline = true, sp = colors.fg },

    -- Completions.
    CmpItemAbbrDeprecated = { link = 'DiagnosticDeprecated' },
    CmpItemAbbrMatch = { fg = colors.cyan, bg = 'NONE' },
    CmpItemMenu = { fg = colors.grey },
    CmpItemKind = { bg = 'NONE' },
    CmpItemKindClass = { link = '@type' },
    CmpItemKindColor = { link = 'DevIconCss' },
    CmpItemKindConstant = { link = '@constant' },
    CmpItemKindConstructor = { link = '@type' },
    CmpItemKindEnum = { link = '@field' },
    CmpItemKindEnumMember = { link = '@field' },
    CmpItemKindEvent = { link = '@constant' },
    CmpItemKindField = { link = '@field' },
    CmpItemKindFile = { link = 'Directory' },
    CmpItemKindFolder = { link = 'Directory' },
    CmpItemKindFunction = { link = '@function' },
    CmpItemKindInterface = { link = '@type' },
    CmpItemKindKeyword = { link = '@keyword' },
    CmpItemKindMethod = { link = '@method' },
    CmpItemKindModule = { link = '@namespace' },
    CmpItemKindOperator = { link = '@operator' },
    CmpItemKindProperty = { link = '@property' },
    CmpItemKindReference = { link = '@parameter.reference' },
    CmpItemKindSnippet = { link = '@text' },
    CmpItemKindStruct = { link = '@structure' },
    CmpItemKindText = { link = '@text' },
    CmpItemKindTypeParameter = { link = '@parameter' },
    CmpItemKindUnit = { link = '@field' },
    CmpItemKindValue = { link = '@field' },
    CmpItemKindVariable = { link = '@variable' },

    -- Dap UI.
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
    NvimDapVirtualText = { fg = colors.lavender, underline = true },

    -- Make whitespace less prominent.
    Whitespace = { fg = '#292d32' },

    -- Diffs.
    DiffAdd = { fg = colors.green, bg = colors.transparent_green },
    DiffChange = { fg = colors.yellow, bg = colors.transparent_yellow },
    DiffDelete = { fg = colors.red, bg = colors.transparent_red },
    DiffText = { fg = colors.bright_white, bg = colors.transparent_black },
    diffAdded = { fg = colors.bright_green, bold = true },
    diffChanged = { fg = colors.bright_yellow, bold = true },
    diffRemoved = { fg = colors.bright_red, bold = true },

    -- Command line.
    MoreMsg = { fg = colors.bright_white, bold = true },
    MsgArea = { fg = colors.cyan },
    MsgSeparator = { fg = colors.lilac },

    -- Winbar styling.
    WinBar = { fg = colors.fg, bg = colors.transparent_black },
    WinBarSeparator = { fg = colors.green, bg = colors.transparent_black },
    WinBarSpecial = { fg = colors.bright_magenta, bg = colors.transparent_black, italic = true },

    -- Quickfix window.
    qfPath = { fg = colors.bright_blue },
    qfPosition = { fg = colors.pink, underline = true },
    QuickFixLine = { italic = true, bg = colors.transparent_red },
    BqfPreviewRange = { fg = colors.bg, bg = colors.bright_magenta },

    -- Gitsigns.
    GitSignsAdd = { fg = colors.bright_green },
    GitSignsChange = { fg = colors.cyan },
    GitSignsDelete = { fg = colors.bright_red },

    -- Bufferline.
    BufferLineBufferSelected = { bg = colors.bg, underline = true, sp = colors.purple },
    BufferLineFill = { bg = colors.bg },
    TabLine = { fg = colors.comment, bg = colors.bg },
    TabLineFill = { bg = colors.bg },
    TabLineSel = { bg = colors.purple },

    -- Start dashboard.
    AlphaHeader = { fg = colors.purple },
    AlphaButtons = { fg = colors.cyan },
    AlphaShortcut = { fg = colors.orange },
    AlphaFooter = { fg = colors.purple, italic = true },

    -- When triggering flash, use a white font and make everything in the backdrop italic.
    FlashPrompt = { link = 'Normal' },
    FlashBackdrop = { italic = true },

    -- Make these titles more visible.
    MiniClueTitle = { bold = true, fg = colors.cyan },
    MiniFilesTitleFocused = { bold = true, fg = colors.cyan },

    -- Nicer yanky highlights.
    YankyPut = { link = 'Visual' },
    YankyYanked = { link = 'Visual' },

    -- Highlight for the Treesitter sticky context.
    TreesitterContextBottom = { underline = true, sp = colors.lilac },

    -- Fzf overrides.
    FzfLuaBorder = { fg = colors.comment },
    FzfLuaHeaderText = { fg = colors.pink },
    FzfLuaHeaderBind = { fg = colors.lavender },
    FzfLuaPreviewTitle = { fg = colors.fg },
    FzfLuaSearch = { bg = colors.transparent_red },

    -- TODOs and notes.
    MiniHipatternsTodo = { fg = colors.bg, bg = colors.cyan, bold = true },
    MiniHipatternsNote = { fg = colors.bg, bg = colors.bright_green, bold = true },
    MiniHipatternsHack = { fg = colors.bg, bg = colors.orange, bold = true },

    -- Overseeer.
    OverseerComponent = { link = '@keyword' },
})

for group, opts in pairs(groups) do
    vim.api.nvim_set_hl(0, group, opts)
end
