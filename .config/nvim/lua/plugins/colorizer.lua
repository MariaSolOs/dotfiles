-- Highlight colors.
return {
    {
        'norcalli/nvim-colorizer.lua',
        ft = { 'lua', 'conf' },
        -- stylua: ignore
        opts = { 'lua'; 'conf' },
        init = function()
            -- *.conf files don't have a filetype in Neovim, so we set it here
            -- so that we can highlight colors.
            vim.api.nvim_create_autocmd('BufReadPost', {
                group = vim.api.nvim_create_augroup('SetConfFiletype', { clear = true }),
                pattern = '*.conf',
                callback = function()
                    vim.cmd 'setlocal filetype=conf'
                    vim.cmd 'ColorizerAttachToBuffer'
                end,
            })
        end,
    },
}
