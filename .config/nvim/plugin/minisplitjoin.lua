local add = require('vim-pack').add

-- Split/join blocks of code.
add {
    {
        src = 'nvim-mini/mini.splitjoin',
        opts = {
            mappings = {
                toggle = '<leader>cj',
            },
        },
    },
}
