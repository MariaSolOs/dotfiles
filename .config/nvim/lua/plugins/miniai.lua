-- Better text objects.
return {
    {
        'echasnovski/mini.ai',
        event = 'VeryLazy',
        dependencies = 'nvim-treesitter-textobjects',
        config = function()
            local miniai = require 'mini.ai'

            miniai.setup {
                n_lines = 300,
                custom_textobjects = {
                    o = miniai.gen_spec.treesitter({
                        a = { '@block.outer', '@conditional.outer', '@loop.outer' },
                        i = { '@block.inner', '@conditional.inner', '@loop.inner' },
                    }, {}),
                    f = miniai.gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' }, {}),
                    c = miniai.gen_spec.treesitter({ a = '@class.outer', i = '@class.inner' }, {}),
                },
            }
        end,
    },
}
