-- Install with: @vtsls/language-server

local jsts_settings = {
    suggest = { completeFunctionCalls = true },
    inlayHints = {
        functionLikeReturnTypes = { enabled = true },
        parameterNames = { enabled = 'literals' },
        variableTypes = { enabled = true },
    },
}

local function get_global_tsdk()
    -- Use VS Code's bundled copy if available.
    local vscode_tsdk_path = '/Applications/%s/Contents/Resources/app/extensions/node_modules/typescript/lib'
    local vscode_tsdk = vscode_tsdk_path:format 'Visual Studio Code.app'
    local vscode_insiders_tsdk = vscode_tsdk_path:format 'Visual Studio Code - Insiders.app'

    if vim.fn.isdirectory(vscode_tsdk) == 1 then
        return vscode_tsdk
    elseif vim.fn.isdirectory(vscode_insiders_tsdk) == 1 then
        return vscode_insiders_tsdk
    else
        return nil
    end
end

---@type vim.lsp.Config
return {
    cmd = { 'vtsls', '--stdio' },
    filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
    root_markers = { 'tsconfig.json', 'jsonconfig.json' },
    settings = {
        typescript = jsts_settings,
        javascript = jsts_settings,
        vtsls = {
            typescript = {
                globalTsdk = get_global_tsdk(),
            },
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
