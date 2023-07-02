-- Markdown previewer.
-- TODO: Use https://github.com/toppair/peek.nvim when they fix their bundle issues.
return {
    {
        'iamcco/markdown-preview.nvim',
        ft = 'markdown',
        build = function()
            vim.fn['mkdp#util#install']()
        end,
        config = function()
            vim.keymap.set('n', '<leader>M', ':MarkdownPreviewToggle<cr>', { desc = 'Toggle .md preview' })
        end,
    },
}
