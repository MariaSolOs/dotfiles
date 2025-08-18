-- Install with: go install golang.org/x/tools/gopls@latest

---@type vim.lsp.Config
return {
    cmd = { 'gopls' },
    filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
}
