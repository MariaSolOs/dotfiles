-- Install with: @vtsls/language-server

local jsts_settings = {
    suggest = { completeFunctionCalls = true },
    inlayHints = {
        functionLikeReturnTypes = { enabled = true },
        parameterNames = { enabled = 'literals' },
        variableTypes = { enabled = true },
    },
}

---@type vim.lsp.Config
return {
    cmd = { 'vtsls', '--stdio' },
    filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
    root_markers = { 'tsconfig.json', 'jsonconfig.json' },
    settings = {
        typescript = jsts_settings,
        javascript = jsts_settings,
        vtsls = {
            -- Automatically use workspace version of TypeScript lib on startup.
            autoUseWorkspaceTsdk = true,
            experimental = {
                -- Inlay hint truncation.
                maxInlayHintLength = 30,
                -- For completion performance.
                completion = {
                    enableServerSideFuzzyMatch = true,
                },
            },
        },
    },
}
