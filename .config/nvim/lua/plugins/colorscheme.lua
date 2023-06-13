-- Color theme.
return {
    {
        'Mofiqul/dracula.nvim',
        lazy = false,
        priority = 1000,
        config = function(_, opts)
            require('dracula').setup(opts)
            vim.cmd.colorscheme 'dracula'
        end,
        opts = {
            colors = {
                bg = '#0E1419',
                fg = '#FBEAFF',
                orange = '#FFAACF'
            },
            italic_comment = true,
        }
    }
}
