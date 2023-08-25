-- Make the quickfix list greattt.
return {
    {
        'kevinhwang91/nvim-bqf',
        ft = 'qf',
        dependencies = {
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
