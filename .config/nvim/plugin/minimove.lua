local add_on_event = require('vim-pack').add_on_event

-- Moving selections.
add_on_event('BufReadPre', {
    {
        src = 'nvim-mini/mini.move',
        opts = {},
    },
})
