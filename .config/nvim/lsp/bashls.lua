-- Install with: npm i -g bash-language-server
-- Also uses shellcheck for diagnostics and shfmt for formatting (need to be installed separately).

---@type vim.lsp.Config
return {
    cmd = { 'bash-language-server', 'start' },
    filetypes = { 'bash', 'sh', 'zsh' },
}
