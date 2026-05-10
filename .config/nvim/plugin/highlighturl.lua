local add_on_event = require('vim-pack').add_on_event

-- Highlight URLs.
add_on_event('UIEnter', {
    {
        src = 'itchyny/vim-highlighturl',
        -- Vimscript-only plugin: skip require/setup entirely.
        setup = false,
        on_setup = function()
            -- Disable the plugin in some places where the default highlighting is preferred.
            vim.api.nvim_create_autocmd('FileType', {
                desc = 'Disable URL highlights',
                pattern = { 'fzf' },
                command = 'call highlighturl#disable_local()',
            })
        end,
    },
})
