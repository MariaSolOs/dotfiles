-- Split/join blocks of code.
return {
    {
        'Wansmer/treesj',
        dependencies = 'nvim-treesitter',
        keys = {
            { 'J', '<cmd>TSJToggle<cr>', desc = 'Toggle join code block' },
        },
        opts = {
            use_default_keymaps = false,
        },
    },
}
