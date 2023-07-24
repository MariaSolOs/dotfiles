local icons = require('helpers.icons').diagnostics

-- Pretty list for diagnostics, references, etc.
return {
    'folke/trouble.nvim',
    cmd = { 'Trouble', 'TroubleToggle' },
    dependencies = 'nvim-tree/nvim-web-devicons',
    opts = {
        signs = {
            error = icons.Error,
            warning = icons.Warn,
            hint = icons.Hint,
            information = icons.Info,
        },
        win_border = 'rounded',
    },
    keys = {
        {
            '<leader>xd',
            ':TroubleToggle document_diagnostics<cr>',
            desc = 'Document diagnostics',
        },
        {
            '<leader>xw',
            ':TroubleToggle workspace_diagnostics<cr>',
            desc = 'Workspace diagnostics',
        },
        {
            '<leader>xq',
            ':TroubleToggle quickfix<cr>',
            desc = 'Quickfix list',
        },
    },
}
