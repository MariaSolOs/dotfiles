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
    neon_cyan = '#00DFDF',
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
    CurSearch = { fg = colors.black, bg = colors.fuchsia },
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
    IncSearch = { link = 'CurSearch' },
    Include = { fg = colors.purple },
    Keyword = { fg = colors.cyan },
    Label = { fg = colors.cyan },
    LineNr = { fg = colors.lilac },
    Macro = { fg = colors.purple },
    MatchParen = { sp = colors.fg, underline = true },
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
    SpellBad = { sp = colors.bright_red, underline = true },
    SpellCap = { sp = colors.yellow, underline = true },
    SpellLocal = { sp = colors.yellow, underline = true },
    SpellRare = { sp = colors.yellow, underline = true },
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

    -- Treesitter.
    ['@annotation'] = { fg = colors.yellow },
    ['@attribute'] = { fg = colors.cyan },
    ['@boolean'] = { fg = colors.purple },
    ['@character'] = { fg = colors.green },
    ['@constant'] = { fg = colors.purple },
    ['@constant.builtin'] = { fg = colors.purple },
    ['@constant.macro'] = { fg = colors.cyan },
    ['@constructor'] = { fg = colors.cyan },
    ['@error'] = { fg = colors.bright_red },
    ['@function'] = { fg = colors.green },
    ['@function.builtin'] = { fg = colors.cyan },
    ['@function.macro'] = { fg = colors.green },
    ['@function.method'] = { fg = colors.green },
    ['@keyword'] = { fg = colors.pink },
    ['@keyword.conditional'] = { fg = colors.pink },
    ['@keyword.exception'] = { fg = colors.purple },
    ['@keyword.function'] = { fg = colors.cyan },
    ['@keyword.function.ruby'] = { fg = colors.pink },
    ['@keyword.include'] = { fg = colors.pink },
    ['@keyword.operator'] = { fg = colors.pink },
    ['@keyword.repeat'] = { fg = colors.pink },
    ['@label'] = { fg = colors.cyan },
    ['@markup'] = { fg = colors.orange },
    ['@markup.emphasis'] = { fg = colors.yellow, italic = true },
    ['@markup.heading'] = { fg = colors.pink, bold = true },
    ['@markup.link'] = { fg = colors.orange, bold = true },
    ['@markup.link.uri'] = { fg = colors.yellow, italic = true },
    ['@markup.list'] = { fg = colors.cyan },
    ['@markup.raw'] = { fg = colors.yellow },
    ['@markup.strong'] = { fg = colors.orange, bold = true },
    ['@markup.underline'] = { fg = colors.orange },
    ['@module'] = { fg = colors.orange },
    ['@number'] = { fg = colors.purple },
    ['@number.float'] = { fg = colors.green },
    ['@operator'] = { fg = colors.pink },
    ['@parameter.reference'] = { fg = colors.orange },
    ['@property'] = { fg = colors.purple },
    ['@punctuation.bracket'] = { fg = colors.fg },
    ['@punctuation.delimiter'] = { fg = colors.fg },
    ['@string'] = { fg = colors.yellow },
    ['@string.escape'] = { fg = colors.cyan },
    ['@string.regexp'] = { fg = colors.bright_red },
    ['@string.special.symbol'] = { fg = colors.purple },
    ['@structure'] = { fg = colors.purple },
    ['@tag'] = { fg = colors.cyan },
    ['@tag.attribute'] = { fg = colors.green },
    ['@tag.delimiter'] = { fg = colors.cyan },
    ['@type'] = { fg = colors.bright_cyan },
    ['@type.builtin'] = { fg = colors.cyan, italic = true },
    ['@type.qualifier'] = { fg = colors.pink },
    ['@variable'] = { fg = colors.fg },
    ['@variable.builtin'] = { fg = colors.purple },
    ['@variable.member'] = { fg = colors.orange },
    ['@variable.parameter'] = { fg = colors.orange },

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

    -- Package manager.
    LazyDimmed = { fg = colors.grey },

    -- LSP.
    DiagnosticDeprecated = { strikethrough = true, fg = colors.fg },
    DiagnosticError = { fg = colors.red },
    DiagnosticFloatingError = { fg = colors.red },
    DiagnosticFloatingHint = { fg = colors.cyan },
    DiagnosticFloatingInfo = { fg = colors.cyan },
    DiagnosticFloatingWarn = { fg = colors.yellow },
    DiagnosticHint = { fg = colors.cyan },
    DiagnosticInfo = { fg = colors.cyan },
    DiagnosticUnderlineError = { undercurl = true, sp = colors.red },
    DiagnosticUnderlineHint = { undercurl = true, sp = colors.cyan },
    DiagnosticUnderlineInfo = { undercurl = true, sp = colors.cyan },
    DiagnosticUnderlineWarn = { undercurl = true, sp = colors.yellow },
    DiagnosticUnnecessary = { fg = colors.grey, italic = true },
    DiagnosticVirtualTextError = { fg = colors.red, bg = colors.transparent_red },
    DiagnosticVirtualTextHint = { fg = colors.cyan, bg = colors.transparent_blue },
    DiagnosticVirtualTextInfo = { fg = colors.cyan, bg = colors.transparent_blue },
    DiagnosticVirtualTextWarn = { fg = colors.yellow, bg = colors.transparent_yellow },
    DiagnosticWarn = { fg = colors.yellow },
    LspCodeLens = { fg = colors.cyan },
    LspFloatWinBorder = { fg = colors.comment },
    LspInlayHint = { fg = colors.lavender, italic = true },
    LspReferenceRead = { bg = colors.transparent_blue },
    LspReferenceText = {},
    LspReferenceWrite = { bg = colors.transparent_red },
    LspSignatureActiveParameter = { bold = true, underline = true, sp = colors.fg },

    -- Completions:
    BlinkCmpKindClass = { link = '@type' },
    BlinkCmpKindColor = { link = 'DevIconCss' },
    BlinkCmpKindConstant = { link = '@constant' },
    BlinkCmpKindConstructor = { link = '@type' },
    BlinkCmpKindEnum = { link = '@variable.member' },
    BlinkCmpKindEnumMember = { link = '@variable.member' },
    BlinkCmpKindEvent = { link = '@constant' },
    BlinkCmpKindField = { link = '@variable.member' },
    BlinkCmpKindFile = { link = 'Directory' },
    BlinkCmpKindFolder = { link = 'Directory' },
    BlinkCmpKindFunction = { link = '@function' },
    BlinkCmpKindInterface = { link = '@type' },
    BlinkCmpKindKeyword = { link = '@keyword' },
    BlinkCmpKindMethod = { link = '@function.method' },
    BlinkCmpKindModule = { link = '@module' },
    BlinkCmpKindOperator = { link = '@operator' },
    BlinkCmpKindProperty = { link = '@property' },
    BlinkCmpKindReference = { link = '@parameter.reference' },
    BlinkCmpKindSnippet = { link = '@markup' },
    BlinkCmpKindStruct = { link = '@structure' },
    BlinkCmpKindText = { link = '@markup' },
    BlinkCmpKindTypeParameter = { link = '@variable.parameter' },
    BlinkCmpKindUnit = { link = '@variable.member' },
    BlinkCmpKindValue = { link = '@variable.member' },
    BlinkCmpKindVariable = { link = '@variable' },
    BlinkCmpLabelDeprecated = { link = 'DiagnosticDeprecated' },
    BlinkCmpLabelDescription = { fg = colors.grey, italic = true },
    BlinkCmpLabelDetail = { fg = colors.grey, bg = colors.bg },
    BlinkCmpMenu = { bg = colors.bg },
    BlinkCmpMenuBorder = { bg = colors.bg },

    -- Dap UI.
    DapStoppedLine = { default = true, link = 'Visual' },
    DapUIBreakpointsCurrentLine = { fg = colors.bright_green, bold = true },
    DapUIBreakpointsInfo = { fg = colors.bright_green },
    DapUIBreakpointsPath = { fg = colors.bright_cyan },
    DapUIDecoration = { fg = colors.bright_cyan },
    DapUIFloatBorder = { fg = colors.bright_cyan },
    DapUILineNumber = { fg = colors.bright_cyan },
    DapUIModifiedValue = { fg = colors.bright_cyan, bold = true },
    DapUIPlayPause = { fg = colors.bright_green },
    DapUIRestart = { fg = colors.green },
    DapUIScope = { fg = colors.bright_cyan },
    DapUISource = { fg = colors.bright_blue },
    DapUIStepBack = { fg = colors.cyan },
    DapUIStepInto = { fg = colors.cyan },
    DapUIStepOut = { fg = colors.cyan },
    DapUIStepOver = { fg = colors.cyan },
    DapUIStop = { fg = colors.red },
    DapUIStoppedThread = { fg = colors.bright_cyan },
    DapUIThread = { fg = colors.bright_green },
    DapUIType = { fg = colors.bright_blue },
    DapUIWatchesEmpty = { fg = colors.pink },
    DapUIWatchesError = { fg = colors.pink },
    DapUIWatchesValue = { fg = colors.bright_green },
    DapUIWinSelect = { fg = colors.bright_cyan, bold = true },
    NvimDapVirtualText = { fg = colors.lavender, underline = true },

    -- Diffs.
    DiffAdd = { fg = colors.green, bg = colors.transparent_green },
    DiffChange = { fg = colors.white, bg = colors.transparent_yellow },
    DiffDelete = { fg = colors.red, bg = colors.transparent_red },
    DiffText = { fg = colors.orange, bg = colors.transparent_yellow, bold = true },
    DiffviewFolderSign = { fg = colors.cyan },
    DiffviewNonText = { fg = colors.lilac },
    diffAdded = { fg = colors.bright_green, bold = true },
    diffChanged = { fg = colors.bright_yellow, bold = true },
    diffRemoved = { fg = colors.bright_red, bold = true },

    -- Command line.
    MoreMsg = { fg = colors.bright_white, bold = true },
    MsgArea = { fg = colors.cyan },
    MsgSeparator = { fg = colors.lilac },

    -- Winbar styling.
    WinBar = { fg = colors.fg, bg = colors.transparent_black },
    WinBarNC = { bg = colors.transparent_black },
    WinBarDir = { fg = colors.bright_magenta, bg = colors.transparent_black, italic = true },
    WinBarSeparator = { fg = colors.green, bg = colors.transparent_black },

    -- Quickfix window.
    QuickFixLine = { italic = true, bg = colors.transparent_red },

    -- Gitsigns.
    GitSignsAdd = { fg = colors.bright_green },
    GitSignsChange = { fg = colors.cyan },
    GitSignsDelete = { fg = colors.bright_red },
    GitSignsStagedAdd = { fg = colors.orange },
    GitSignsStagedChange = { fg = colors.orange },
    GitSignsStagedDelete = { fg = colors.orange },

    -- Bufferline.
    BufferLineBufferSelected = { bg = colors.bg, underline = true, sp = colors.purple },
    BufferLineFill = { bg = colors.bg },
    TabLine = { fg = colors.comment, bg = colors.bg },
    TabLineFill = { bg = colors.bg },
    TabLineSel = { bg = colors.purple },

    -- When triggering flash, use a white font and make everything in the backdrop italic.
    FlashBackdrop = { italic = true },
    FlashPrompt = { link = 'Normal' },

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
    FzfLuaHeaderBind = { fg = colors.lavender },
    FzfLuaHeaderText = { fg = colors.pink },
    FzfLuaLivePrompt = { link = 'Normal' },
    FzfLuaLiveSym = { fg = colors.fuchsia },
    FzfLuaPreviewTitle = { fg = colors.fg },
    FzfLuaSearch = { bg = colors.transparent_red },

    -- Nicer sign column highlights for grug-far.
    GrugFarResultsChangeIndicator = { link = 'Changed' },
    GrugFarResultsRemoveIndicator = { link = 'Removed' },
    GrugFarResultsAddIndicator = { link = 'Added' },

    -- TODOs and notes.
    MiniHipatternsHack = { fg = colors.bg, bg = colors.orange, bold = true },
    MiniHipatternsNote = { fg = colors.bg, bg = colors.bright_green, bold = true },
    MiniHipatternsTodo = { fg = colors.bg, bg = colors.cyan, bold = true },

    -- Overseeer.
    OverseerComponent = { link = '@keyword' },

    -- Links.
    HighlightUrl = { underline = true, fg = colors.neon_cyan, sp = colors.neon_cyan },
})

for group, opts in pairs(groups) do
    vim.api.nvim_set_hl(0, group, opts)
end
