-- Highlight patterns in text.
return {
    {
        'echasnovski/mini.hipatterns',
        event = 'BufReadPost',
        opts = function()
            local highlighters = {
                hex_color = require('mini.hipatterns').gen_highlighter.hex_color(),
            }
            for _, word in ipairs { 'todo', 'note', 'hack' } do
                highlighters[word] = {
                    pattern = string.format('%%f[%%w]()%s()%%f[%%W]', word:upper()),
                    group = string.format('MiniHipatterns%s', word:sub(1, 1):upper() .. word:sub(2)),
                }
            end

            return { highlighters = highlighters }
        end,
    },
}
