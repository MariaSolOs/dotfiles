local add_on_event = require('vim-pack').add_on_event

-- Autoclosing tags for HTML and JSX.
add_on_event('InsertEnter', {
    {
        src = 'windwp/nvim-ts-autotag',
        opts = {},
    },
})
