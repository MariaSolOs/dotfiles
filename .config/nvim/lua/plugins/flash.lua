-- Navigation with jump motions.
return {
    {
        'folke/flash.nvim',
        event = 'VeryLazy',
        opts = {
            jump = {
                autojump = true,
            },
            modes = {
                -- Disable ft motions.
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
            },
        },
        init = function()
            -- When triggered, make everything in the backdrop italic.
            vim.api.nvim_set_hl(0, 'FlashBackdrop', { italic = true })
        end,
    },
}
