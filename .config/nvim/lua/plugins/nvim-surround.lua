-- Surround selections, add quotes, etc.
return {
    {
        'kylechui/nvim-surround',
        event = 'VeryLazy',
        opts = {
            keymaps = {
                visual = 'Y',
            },
        },
    },
}
