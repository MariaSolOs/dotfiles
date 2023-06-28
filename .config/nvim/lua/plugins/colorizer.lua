-- Highlight colors.
return {
    {
        'norcalli/nvim-colorizer.lua',
        ft = { 'lua', 'conf' },
        -- stylua: ignore
        opts = { 'lua'; 'conf' },
        init = function()
            -- *.conf files don't have a filetype in Neovim, so we set it here
            -- so that we can colorize colors.
            vim.api.nvim_create_autocmd('BufReadPost', {
                group = require('helpers.commands').augroup 'SetConfFiletype',
                pattern = '*.conf',
                callback = function()
                    vim.cmd 'setlocal filetype=conf'
                    vim.cmd 'ColorizerAttachToBuffer'
                end,
            })
        end,
    },
}
