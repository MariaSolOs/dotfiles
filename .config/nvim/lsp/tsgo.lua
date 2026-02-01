-- Install with: npm i -g @typescript/native-preview

---@type vim.lsp.Config
return {
    cmd = { 'tsgo', '--lsp', '--stdio' },
    filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
    root_dir = function(bufnr, on_dir)
        local root_markers = { { 'package-lock.json', 'yarn.lock', 'pnpm-lock.yaml' }, { '.git' } }

        -- Fallback to the current working directory if no project root is found.
        local project_root = vim.fs.root(bufnr, root_markers) or vim.fn.getcwd()

        on_dir(project_root)
    end,
}
