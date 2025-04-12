-- Install with: cargo install --features lsp --locked taplo-cli

---@type vim.lsp.Config
return {
    cmd = { 'taplo', 'lsp', 'stdio' },
    filetypes = { 'toml' },
    settings = {
        -- Use the defaults that the VSCode extension uses: https://github.com/tamasfe/taplo/blob/2e01e8cca235aae3d3f6d4415c06fd52e1523934/editors/vscode/package.json
        taplo = {
            configFile = { enabled = true },
            schema = {
                enabled = true,
                catalogs = { 'https://www.schemastore.org/api/json/catalog.json' },
                cache = {
                    memoryExpiration = 60,
                    diskExpiration = 600,
                },
            },
        },
    },
}
