-- Pretty list for diagnostics, references, etc.
return {
    'folke/trouble.nvim',
    cmd = { 'Trouble', 'TroubleToggle' },
    dependencies = 'nvim-tree/nvim-web-devicons',
    opts = {
        auto_close = true,
        use_diagnostic_signs = true,
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
