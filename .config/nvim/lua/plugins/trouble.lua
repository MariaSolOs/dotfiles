-- Pretty list for diagnostics, references, etc.
return {
    'folke/trouble.nvim',
    cmd = { 'Trouble', 'TroubleToggle' },
    dependencies = 'nvim-tree/nvim-web-devicons',
    opts = {
        padding = false,
    },
    keys = {
        {
            '<leader>td',
            ':TroubleToggle workspace_diagnostics<cr>',
            desc = 'Toggle diagnostics',
            { silent = true, noremap = true },
        },
        {
            '<leader>tq',
            ':TroubleToggle quickfix<cr>',
            desc = 'Toggle quickfix list',
            { silent = true, noremap = true },
        },
    },
}
