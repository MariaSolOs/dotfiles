local add = require('vim-pack').add

-- File icons used by the statusline and pickers.
add {
    {
        src = 'nvim-tree/nvim-web-devicons',
        opts = {
            -- Make the icon for query files more visible.
            override = {
                scm = {
                    icon = '󰘧',
                    color = '#A9ABAC',
                    cterm_color = '16',
                    name = 'Scheme',
                },
            },
        },
    },
}
