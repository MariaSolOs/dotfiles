-- Create Color Code.
return {
    {
        'uga-rosa/ccc.nvim',
        ft = { 'lua', 'conf' },
        cmd = 'CccPick',
        opts = {
            highlighter = {
                auto_enable = true,
                filetypes = { 'lua', 'conf' },
            },
        },
    },
}
