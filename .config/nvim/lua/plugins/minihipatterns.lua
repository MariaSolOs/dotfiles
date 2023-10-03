-- Highlight patterns in text.
return {
    {
        'echasnovski/mini.hipatterns',
        event = 'BufReadPost',
        opts = function()
            return {
                highlighters = {
                    hex_color = require('mini.hipatterns').gen_highlighter.hex_color(),
                    todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsTodo' },
                    note = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'MiniHipatternsNote' },
                    hack = { pattern = '%f[%w]()HACK()%f[%W]', group = 'MiniHipatternsHack' },
                },
            }
        end,
    },
}
