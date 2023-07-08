-- Pretty list for diagnostics, references, etc.
return {
    'folke/trouble.nvim',
    cmd = { 'Trouble', 'TroubleToggle' },
    dependencies = 'nvim-tree/nvim-web-devicons',
    opts = {
        -- Don't add an extra newline above the list.
        padding = false,
        auto_close = true,
    },
    keys = {
        {
            '<leader>xd',
            ':TroubleToggle document_diagnostics<cr>',
            desc = 'Document diagnostics',
            { silent = true, noremap = true },
        },
        {
            '<leader>xw',
            ':TroubleToggle workspace_diagnostics<cr>',
            desc = 'Workspace diagnostics',
            { silent = true, noremap = true },
        },
        {
            '<leader>xq',
            ':TroubleToggle quickfix<cr>',
            desc = 'Quickfix list',
            { silent = true, noremap = true },
        },
    },
}
