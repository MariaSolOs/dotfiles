local icons = require('icons').diagnostics

-- Pretty list for diagnostics, references, etc.
-- TODO: Replace this by quickfix plugins?
return {
    {
        'folke/trouble.nvim',
        cmd = { 'Trouble', 'TroubleToggle' },
        dependencies = 'nvim-tree/nvim-web-devicons',
        opts = {
            signs = {
                error = icons.ERROR,
                warning = icons.WARN,
                hint = icons.HINT,
                information = icons.INFO,
            },
            auto_close = true,
            win_config = { border = 'rounded' },
        },
        keys = {
            {
                '<leader>xd',
                '<cmd>TroubleToggle document_diagnostics<cr>',
                desc = 'Document diagnostics',
            },
            {
                '<leader>xw',
                '<cmd>TroubleToggle workspace_diagnostics<cr>',
                desc = 'Workspace diagnostics',
            },
            {
                '<leader>xq',
                '<cmd>TroubleToggle quickfix<cr>',
                desc = 'Quickfix list',
            },
        },
    },
}
