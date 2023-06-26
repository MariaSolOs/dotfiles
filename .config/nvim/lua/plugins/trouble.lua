-- Pretty list for diagnostics, references, etc.
return {
    'folke/trouble.nvim',
    cmd = { 'Trouble', 'TroubleToggle' },
    dependencies = 'nvim-tree/nvim-web-devicons',
    opts = {
        -- Don't add an extra newline above the list.
        padding = false,
    },
    keys = {
        {
            '<leader>td',
            ':TroubleToggle workspace_diagnostics<cr>',
            desc = 'Diagnostics',
            { silent = true, noremap = true },
        },
        {
            '<leader>tq',
            ':TroubleToggle quickfix<cr>',
            desc = 'Quickfix list',
            { silent = true, noremap = true },
        },
    },
}
