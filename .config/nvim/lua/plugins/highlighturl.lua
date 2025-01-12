-- Highlight URLs.
return {
    {
        'itchyny/vim-highlighturl',
        event = 'VeryLazy',
        config = function()
            -- Disable the plugin in some places where the default highlighting
            -- is preferred.
            vim.api.nvim_create_autocmd('FileType', {
                desc = 'Disable URL highlights',
                pattern = {
                    'fzf',
                    'lazyterm',
                },
                command = 'call highlighturl#disable_local()',
            })
        end,
    },
}
