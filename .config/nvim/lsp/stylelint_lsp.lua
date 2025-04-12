-- Install with: npm i -g stylelint-lsp

---@type vim.lsp.Config
return {
    cmd = { 'stylelint-lsp', '--stdio' },
    filetypes = { 'css', 'less', 'scss' },
    root_markers = { '.stylelintrc', '.stylelintrc.js', '.stylelintrc.json', 'stylelint.config.js' },
    settings = {
        stylelintplus = {
            -- Lint on save instead of on type.
            validateOnSave = true,
            validateOnType = false,
        },
    },
}
