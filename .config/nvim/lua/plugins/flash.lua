-- Navigation with jump motions.
return {
    {
        'folke/flash.nvim',
        event = 'VeryLazy',
        opts = {
            modes = {
                char = {
                    enabled = false,
                },
            },
        },
        keys = {
            {
                's',
                mode = { 'n', 'x', 'o' },
                function()
                    require('flash').jump()
                end,
                desc = 'Flash Jump',
            },
        },
        init = function()
            vim.api.nvim_set_hl(0, 'FlashBackdrop', { italic = true })
        end,
    },
}
