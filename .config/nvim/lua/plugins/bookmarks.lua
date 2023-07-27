-- Bookmark important code.
return {
    {
        'crusj/bookmarks.nvim',
        dependencies = 'nvim-web-devicons',
        opts = {
            keymap = {
                toggle = '<leader>mt',
                add = '<leader>ma',
                delete_on_virt = '<leader>md',
            },
            virt_pattern = { '*.ts', '*.lua', '*.rs' },
            virt_text = '',
            border_style = 'rounded',
            preview_ratio = 0.6,
        },
        keys = {
            {
                '<leader>mt',
                function()
                    require('bookmarks').toggle_bookmarks()
                end,
                desc = 'Toggle bookmarks window',
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
