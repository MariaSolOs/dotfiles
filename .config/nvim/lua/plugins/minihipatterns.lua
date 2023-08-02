-- Highlight patterns in text.
return {
    {
        'echasnovski/mini.hipatterns',
        event = 'BufReadPre',
        config = function()
            local hi = require 'mini.hipatterns'

            require('mini.hipatterns').setup {
                highlighters = {
                    hex_color = hi.gen_highlighter.hex_color { priority = 2000 },
                },
            }
        end,
    },
}
