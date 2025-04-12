-- Install with: npm i -g vscode-langservers-extracted

---@type vim.lsp.Config
return {
    cmd = { 'vscode-json-language-server', '--stdio' },
    filetypes = { 'json', 'jsonc' },
    settings = {
        json = {
            validate = { enable = true },
            schemas = require('schemastore').json.schemas(),
        },
    },
}
