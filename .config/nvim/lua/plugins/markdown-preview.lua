-- Markdown previewer.
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
