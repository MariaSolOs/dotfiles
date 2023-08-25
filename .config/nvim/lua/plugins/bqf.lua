-- Make the quickfix list greattt.
return {
    {
        'kevinhwang91/nvim-bqf',
        ft = 'qf',
        dependencies = {
            {
                'yorickpeterse/nvim-pqf',
                event = 'VeryLazy',
                opts = {
                    show_multiple_lines = true,
                    max_filename_length = 40,
                },
            },
        },
        opts = {
            func_map = {
                split = '<C-s>',
            },
        },
    },
}
