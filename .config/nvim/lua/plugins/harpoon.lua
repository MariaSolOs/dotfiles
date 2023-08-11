-- File navigation.
return {
    {
        'ThePrimeagen/harpoon',
        keys = {
            {
                '<leader>ha',
                function()
                    require('harpoon.mark').add_file()
                end,
                desc = 'Add file',
            },
            {
                '<leader>hm',
                function()
                    require('harpoon.ui').toggle_quick_menu()
                end,
                desc = 'Toggle menu',
            },
            {
                '[h',
                function()
                    require('harpoon.ui').nav_prev()
                end,
                desc = 'Previous harpoon mark',
            },
            {
                ']h',
                function()
                    require('harpoon.ui').nav_next()
                end,
                desc = 'Next harpoon mark',
            },
        },
        opts = {
            global_settings = {
                excluded_filetypes = {
                    'Trouble',
                    'harpoon',
                    'minifiles',
                },
            },
        },
    },
}
