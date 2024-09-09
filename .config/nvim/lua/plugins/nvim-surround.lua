-- Surround selections, add quotes, etc.
return {
    {
        'kylechui/nvim-surround',
        event = 'VeryLazy',
        opts = {
            keymaps = {
                insert = false,
                insert_line = false,
                visual_line = false,
                normal = 'yz',
                normal_cur = 'yzz',
                normal_line = 'yZ',
                normal_cur_line = 'yZZ',
                visual = 'Z',
            },
        },
    },
}
