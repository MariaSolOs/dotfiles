-- VSCode-like winbar.
return {
    {
        'utilyre/barbecue.nvim',
        name = 'barbecue',
        version = '*',
        event = 'LspAttach',
        dependencies = {
            'SmiteshP/nvim-navic',
            'nvim-tree/nvim-web-devicons',
        },
        opts = {
            attach_navic = false,
            create_autocmd = false,
        },
        config = function(_, opts)
            require('barbecue').setup(opts)

            -- Better perf when moving the cursor.
            vim.api.nvim_create_autocmd({
                'WinScrolled',
                'BufWinEnter',
                'CursorHold',
                'InsertLeave',
                'BufModifiedSet',
            }, {
                group = vim.api.nvim_create_augroup('BarbecueUpdater', {}),
                callback = function()
                    require('barbecue.ui').update()
                end,
            })
        end,
    },
}
