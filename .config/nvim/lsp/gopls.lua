-- Install with: go install golang.org/x/tools/gopls@latest

---@type vim.lsp.Config
return {
    cmd = { 'gopls' },
    root_markers = { 'go.mod' },
    filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
}
