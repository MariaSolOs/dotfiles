-- Create Color Code.
return {
    {
        'uga-rosa/ccc.nvim',
        ft = { 'conf', 'lua', 'zsh' },
        cmd = 'CccPick',
        opts = {
            highlighter = {
                auto_enable = true,
                filetypes = { 'conf', 'lua', 'zsh' },
            },
        },
    },
}
