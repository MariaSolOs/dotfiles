-- Install with
-- mac: brew install dprint
-- Arch: paru -S dprint

---@type vim.lsp.Config
return {
    cmd = { 'dprint', 'lsp' },
    filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'json', 'jsonc', 'graphql' },
}
