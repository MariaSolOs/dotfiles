-- Better text objects.
return {
    {
        'echasnovski/mini.ai',
        event = { 'BufReadPre', 'BufNewFile' },
        dependencies = 'nvim-treesitter-textobjects',
        opts = function()
            local miniai = require 'mini.ai'

            return {
                n_lines = 300,
                custom_textobjects = {
                    o = miniai.gen_spec.treesitter({
                        a = { '@block.outer', '@conditional.outer', '@loop.outer' },
                        i = { '@block.inner', '@conditional.inner', '@loop.inner' },
                    }, {}),
                    f = miniai.gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' }, {}),
                    c = miniai.gen_spec.treesitter({ a = '@class.outer', i = '@class.inner' }, {}),
                },
                -- Disable error feedback.
                silent = true,
                -- Don't use the previous or next text object.
                search_method = 'cover',
                mappings = {
                    -- Disable next/last variants.
                    around_next = '',
                    inside_next = '',
                    around_last = '',
                    inside_last = '',
                },
            }
        end,
    },
}
