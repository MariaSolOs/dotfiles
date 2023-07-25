-- Quick buffer navigation.
return {
    {
        'ThePrimeagen/harpoon',
        dependencies = 'nvim-lua/plenary.nvim',
        config = {
            excluded_filetypes = { 'harpoon', 'Trouble' },
        },
        keys = {
            {
                '<leader>hf',
                function()
                    require('harpoon.mark').add_file()
                end,
                desc = 'Mark file',
            },
            {
                '<leader>hm',
                function()
                    require('harpoon.ui').toggle_quick_menu()
                end,
                desc = 'Toggle quick menu',
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
    },
}
