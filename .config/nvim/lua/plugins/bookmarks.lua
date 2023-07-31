-- Bookmark important code.
return {
    {
        'crusj/bookmarks.nvim',
        event = 'BufReadPost',
        opts = {
            keymap = {
                toggle = '<leader>mt',
                add = '<leader>ma',
                delete_on_virt = '<leader>md',
            },
            -- TODO: Don't hardcode this if https://github.com/crusj/bookmarks.nvim/issues/24 gets addressed.
            virt_pattern = { '*.ts', '*.lua', '*.rs' },
            virt_text = '',
            border_style = 'rounded',
            preview_ratio = 0.6,
        },
        keys = {
            {
                '<leader>mo',
                function()
                    require('bookmarks').open_bookmarks()
                end,
                desc = 'Open bookmarks window',
            },
            {
                '<leader>ma',
                function()
                    require('bookmarks').add_bookmarks()
                end,
                desc = 'Add bookmark',
            },
            {
                '<leader>md',
                function()
                    require('bookmarks.list').delete_on_virt()
                end,
                desc = 'Delete bookmark',
            },
        },
    },
}
