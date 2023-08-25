-- Make the quickfix list greattt.
return {
    {
        'kevinhwang91/nvim-bqf',
        ft = 'qf',
        dependencies = {
            -- TODO: Define my own qf formatter.
            {
                'yorickpeterse/nvim-pqf',
                event = 'VeryLazy',
                opts = { show_multiple_lines = true },
            },
        },
        opts = {
            func_map = {
                split = '<C-s>',
            },
        },
    },
}
