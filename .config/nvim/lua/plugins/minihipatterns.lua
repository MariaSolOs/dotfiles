-- Highlight patterns in text.
return {
    {
        'echasnovski/mini.hipatterns',
        event = 'BufReadPost',
        opts = function(_, opts)
            local hipatterns = require 'mini.hipatterns'

            opts.highlighters = vim.tbl_extend('error', opts.highlighters or {}, {
                hex_color = hipatterns.gen_highlighter.hex_color(),
                todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsTodo' },
                note = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'MiniHipatternsNote' },
            })
        end,
    },
}
