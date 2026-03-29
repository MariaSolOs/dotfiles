--- Install with: cargo install vimdoc-language-server

---@type vim.lsp.Config
return {
    cmd = { 'vimdoc-language-server' },
    filetypes = { 'help' },
    root_markers = { 'doc', '.git' },
    workspace_required = false,
}
