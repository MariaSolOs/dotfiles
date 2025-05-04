-- Install with: npm i -g @vtsls/language-server

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
    root_dir = function(bufnr, cb)
        local fname = vim.uri_to_fname(vim.uri_from_bufnr(bufnr))

        local ts_root = vim.fs.find('tsconfig.json', { upward = true, path = fname })[1]
        -- Use the git root to deal with monorepos where TypeScript is installed in the root node_modules folder.
        local git_root = vim.fs.find('.git', { upward = true, path = fname })[1]

        if git_root then
            cb(vim.fn.fnamemodify(git_root, ':h'))
        elseif ts_root then
            cb(vim.fn.fnamemodify(ts_root, ':h'))
        end
    end,
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
