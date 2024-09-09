-- Recognize some files known to have JSON with comments.
vim.filetype.add {
    filename = {
        ['.eslintrc.json'] = 'jsonc',
    },
    pattern = {
        ['tsconfig*.json'] = 'jsonc',
        ['.*/%.vscode/.*%.json'] = 'jsonc',
    },
}
