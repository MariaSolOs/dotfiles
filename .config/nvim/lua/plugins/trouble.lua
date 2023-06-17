-- Pretty list for diagnostics, references, etc.
return {
    'folke/trouble.nvim',
    cmd = { 'Trouble', 'TroubleToggle' },
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
        -- When opening a diagnostic with <Enter>, close the list.
        -- When opening it with <Tab>, jump to it without closing the list.
        action_keys = {
            jump = '<tab>',
            jump_close = '<cr>',
        },
    },
    keys = {
        {
            '<leader>td',
            ':TroubleToggle workspace_diagnostics<cr>',
            desc = 'Toggle diagnostics',
            { silent = true, noremap = true },
        },
    },
}
