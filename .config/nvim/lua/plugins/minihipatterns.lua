-- Highlight patterns in text.
return {
    {
        'echasnovski/mini.hipatterns',
        event = 'BufReadPost',
        opts = function()
            local hi_words = require('mini.extra').gen_highlighter.words

            return {
                highlighters = {
                    hex_color = require('mini.hipatterns').gen_highlighter.hex_color(),
                    todo = hi_words({ 'TODO' }, 'MiniHipatternsTodo'),
                    note = hi_words({ 'NOTE' }, 'MiniHipatternsNote'),
                    hack = hi_words({ 'HACK' }, 'MiniHipatternsHack'),
                },
            }
        end,
    },
}
