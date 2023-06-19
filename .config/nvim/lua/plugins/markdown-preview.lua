-- Markdown previewer.
return {
    {
        'iamcco/markdown-preview.nvim',
        ft = 'markdown',
        build = function()
            vim.fn['mkdp#util#install']()
        end,
        config = function()
            require('helpers.keybindings').nmap('<leader>M', ':MarkdownPreviewToggle<cr>', 'Toggle .md preview')
        end,
    },
}
