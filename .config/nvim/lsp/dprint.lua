-- Install with
-- mac: brew install dprint
-- Arch: paru -S dprint

---@type vim.lsp.Config
return {
    cmd = { 'dprint', 'lsp' },
    filetypes = {
        'graphql',
        'javascript',
        'javascriptreact',
        'json',
        'jsonc',
        'markdown',
        'typescript',
        'typescriptreact',
    },
}
