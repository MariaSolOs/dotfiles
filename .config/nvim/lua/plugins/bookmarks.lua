-- Bookmark important code.
return {
    {
        'crusj/bookmarks.nvim',
        event = 'BufReadPost',
        opts = {
            mappings_enabled = false,
            -- TODO: Don't hardcode this if https://github.com/crusj/bookmarks.nvim/issues/24 gets addressed.
            virt_pattern = { '*.ts', '*.lua', '*.rs' },
            virt_text = '',
            border_style = 'rounded',
            preview_ratio = 0.6,
        },
        keys = {
            {
                '<leader>po',
                function()
                    require('bookmarks').open_bookmarks()
                end,
                desc = 'Open bookmarks window',
            },
            {
                '<leader>pa',
                function()
                    require('bookmarks').add_bookmarks()
                end,
                desc = 'Add bookmark',
            },
        },
    },
}
