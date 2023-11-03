-- Better text objects.
return {
    {
        'echasnovski/mini.ai',
        event = 'VeryLazy',
        dependencies = 'nvim-treesitter/nvim-treesitter-textobjects',
        opts = function()
            local miniai = require 'mini.ai'
            local miniextras = require 'mini.extra'

            return {
                n_lines = 300,
                custom_textobjects = {
                    b = miniextras.gen_ai_spec.indent(),
                    d = miniextras.gen_ai_spec.diagnostic(),
                    f = miniai.gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' }, {}),
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
